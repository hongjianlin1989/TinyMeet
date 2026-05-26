import Foundation
import Testing
@testable import TinyMeet

struct MockCreateEventEventsRepository: EventsRepositoryProtocol {
    let createHandler: @Sendable (CreateEventRequest) async throws -> NearbyEvent

    func fetchPublicEvents() async throws -> [NearbyEvent] { [] }
    func fetchPrivateEvents() async throws -> [NearbyEvent] { [] }
    func fetchUnifiedFeed(
        types: [String]?,
        postalCode: String?,
        cursor: String?
    ) async throws -> (events: [NearbyEvent], nextCursor: String?) {
        ([], nil)
    }
    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
        try await createHandler(request)
    }
}

struct MockCreateEventFriendsRepository: FriendsRepositoryProtocol {
    let friends: [UserProfile]

    func fetchFriendProfiles() async throws -> [UserProfile] { friends }
    func fetchFriendRequests() async throws -> [UserProfile] { [] }
    func acceptFriendRequest(_ request: UserProfile) async throws { }
    func rejectFriendRequest(_ request: UserProfile) async throws { }
    func addFriend(_ profile: UserProfile) async throws { }
    func removeFriend(_ profile: UserProfile) async throws { }
}

struct MockCreateEventGroupsRepository: GroupsRepositoryProtocol {
    let groups: [MeetupGroup]

    func fetchGroups() async throws -> [MeetupGroup] { groups }
    func fetchGroupInvites() async throws -> [GroupInvite] { [] }
    func acceptGroupInvite(_ invite: GroupInvite) async throws { }
    func rejectGroupInvite(_ invite: GroupInvite) async throws { }
    func createGroup(_ request: CreateGroupRequest) async throws { }
    func fetchGroupDetail(groupID: String) async throws -> GroupDetail { GroupDetail.mockDetails[0] }
    func deleteGroup(groupID: String) async throws { }
    func leaveGroup(groupID: String) async throws -> Bool { true }
    func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
    func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws { }
    func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool { true }
}

@MainActor
struct MockAddressSearchService: AddressSearchServicing {
    let suggestionsHandler: @Sendable (String) async throws -> [AddressSuggestion]
    let resolveHandler: @Sendable (AddressSuggestion) async throws -> ResolvedAddressLocation

    init(
        suggestionsHandler: @escaping @Sendable (String) async throws -> [AddressSuggestion] = { _ in [] },
        resolveHandler: @escaping @Sendable (AddressSuggestion) async throws -> ResolvedAddressLocation = { suggestion in
            ResolvedAddressLocation(suggestion: suggestion, latitude: 0, longitude: 0)
        }
    ) {
        self.suggestionsHandler = suggestionsHandler
        self.resolveHandler = resolveHandler
    }

    func suggestions(for query: String) async throws -> [AddressSuggestion] {
        try await suggestionsHandler(query)
    }

    func resolve(_ suggestion: AddressSuggestion) async throws -> ResolvedAddressLocation {
        try await resolveHandler(suggestion)
    }
}

actor CreateEventRequestRecorder {
    private(set) var requests: [CreateEventRequest] = []

    func record(_ request: CreateEventRequest) {
        requests.append(request)
    }
}

actor SearchQueryRecorder {
    private(set) var queries: [String] = []

    func record(_ query: String) {
        queries.append(query)
    }
}

private let createEventTestFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct CreateEventViewModelTests {
    @MainActor
    // swiftlint:disable function_body_length
    @Test func createFriendsEventSubmitsSelectedFriendUIDsAndNewPrivateFields() async throws {
        let created = NearbyEvent(
            title: "Playground Party",
            locationName: "Central Park",
            timeDescription: "May 4 · 3:00 PM",
            ageRange: "3 - 5",
            distanceDescription: "Just created",
            hostName: "Hosted by You",
            attendeeSummary: "Private friends event",
            themeEmoji: "🛝",
            summary: "A fun private playdate for local families.",
            visibility: .private
        )
        let amy = UserProfile(
            id: "friend-amy",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
        let noah = UserProfile(
            id: "friend-noah",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
        let scheduledAt = try #require(createEventTestFormatter.date(from: "2026-05-03T13:56:44.745Z"))
        let endsAt = try #require(createEventTestFormatter.date(from: "2026-05-03T15:56:44.745Z"))
        let scheduledAtString = createEventTestFormatter.string(from: scheduledAt)
        let endsAtString = createEventTestFormatter.string(from: endsAt)

        let viewModel = CreateEventViewModel(
            title: "Playground Party",
            location: "Central Park",
            scheduledAt: scheduledAt,
            endsAt: endsAt,
            kidsAge: "3 - 5",
            summary: "A fun private playdate for local families.",
            eventMode: .private,
            latitudeText: "37.3349",
            longitudeText: "-122.0090",
            themeEmoji: "🛝",
            symbolName: "figure.play",
            tintName: "orange",
            joinVisibility: .friends,
            selectedFriendIDs: Set([amy.id]),
            eventsRepository: MockCreateEventEventsRepository(createHandler: { request in
                #expect(request.visibility == .private)
                #expect(request.title == "Playground Party")
                #expect(request.locationName == "Central Park")
                #expect(request.latitude == 37.3349)
                #expect(request.longitude == -122.0090)
                #expect(request.ageRange == "3 - 5")
                #expect(request.themeEmoji == "🛝")
                #expect(request.symbolName == "figure.play")
                #expect(request.tintName == "orange")
                #expect(request.summary == "A fun private playdate for local families.")
                #expect(request.audienceType == "friends")
                #expect(request.groupID == nil)
                #expect(request.invitedUIDs == ["friend-amy"])
                #expect(request.eventURL == nil)
                #expect(request.scheduledAt == scheduledAtString)
                #expect(request.endsAt == endsAtString)
                return created
            }),
            friendsRepository: MockCreateEventFriendsRepository(friends: [amy, noah]),
            groupsRepository: MockCreateEventGroupsRepository(groups: [])
        )

        await viewModel.loadAudienceOptions()
        #expect(viewModel.selectedFriendIDs == Set([amy.id]))

        let didCreate = await viewModel.createEvent()
        #expect(didCreate)
        #expect(viewModel.createdEvent?.id == created.id)
        #expect(viewModel.errorMessage == nil)
    }
    // swiftlint:enable function_body_length

    @MainActor
    @Test func createGroupEventRequiresSelectedGroupAndSubmitsEndsAt() async throws {
        let group = MeetupGroup(
            id: "group-123",
            name: "Weekend Hikers",
            location: "Palo Alto",
            memberCount: 0,
            summary: "Easy weekend hikes"
        )
        let scheduledAt = try #require(createEventTestFormatter.date(from: "2026-05-03T13:56:44.745Z"))
        let endsAt = try #require(createEventTestFormatter.date(from: "2026-05-03T16:56:44.745Z"))
        let endsAtString = createEventTestFormatter.string(from: endsAt)

        let viewModel = CreateEventViewModel(
            title: "Playground Party",
            location: "Central Park",
            scheduledAt: scheduledAt,
            endsAt: endsAt,
            kidsAge: "3 - 5",
            summary: "Private group playdate.",
            eventMode: .private,
            latitudeText: "37.4000",
            longitudeText: "-122.1000",
            themeEmoji: "🎉",
            symbolName: "leaf.fill",
            tintName: "mint",
            joinVisibility: .group,
            eventsRepository: MockCreateEventEventsRepository(createHandler: { request in
                #expect(request.visibility == .private)
                #expect(request.audienceType == "group")
                #expect(request.groupID == "group-123")
                #expect(request.invitedUIDs == [])
                #expect(request.endsAt == endsAtString)
                #expect(request.eventURL == nil)
                return await MainActor.run {
                    request.toNearbyEvent()
                }
            }),
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: [group])
        )

        await viewModel.loadAudienceOptions()

        #expect(viewModel.shouldShowGroupPicker)
        #expect(viewModel.selectedGroupID == "group-123")

        let didCreate = await viewModel.createEvent()
        #expect(didCreate)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    // swiftlint:disable function_body_length
    @Test func createPublicEventUsesPublicPayloadAndOmitsPrivateOnlyFields() async throws {
        let created = NearbyEvent(
            title: "Community Picnic",
            locationName: "Town Green",
            timeDescription: "May 3 · 2:15 PM",
            ageRange: "4 - 7",
            distanceDescription: "Community",
            hostName: "Hosted by You",
            attendeeSummary: "New public event",
            themeEmoji: "🌳",
            summary: "Bring snacks and meet local families.",
            eventUrl: "https://tinymeet.app/events/community-picnic",
            visibility: .public
        )
        let scheduledAt = try #require(createEventTestFormatter.date(from: "2026-05-03T14:15:45.592Z"))
        let endsAt = try #require(createEventTestFormatter.date(from: "2026-05-03T16:15:45.592Z"))
        let scheduledAtString = createEventTestFormatter.string(from: scheduledAt)
        let endsAtString = createEventTestFormatter.string(from: endsAt)
        let recorder = CreateEventRequestRecorder()

        let viewModel = CreateEventViewModel(
            title: "Community Picnic",
            location: "Town Green",
            scheduledAt: scheduledAt,
            endsAt: endsAt,
            kidsAge: "4 - 7",
            summary: "Bring snacks and meet local families.",
            eventMode: .public,
            eventURL: "https://tinymeet.app/events/community-picnic",
            latitudeText: "37.7749",
            longitudeText: "-122.4194",
            themeEmoji: "🌳",
            joinVisibility: .friends,
            eventsRepository: MockCreateEventEventsRepository(createHandler: { request in
                await recorder.record(request)
                #expect(request.visibility == .public)
                #expect(request.title == "Community Picnic")
                #expect(request.locationName == "Town Green")
                #expect(request.latitude == 37.7749)
                #expect(request.longitude == -122.4194)
                #expect(request.ageRange == "4 - 7")
                #expect(request.themeEmoji == "🌳")
                #expect(request.summary == "Bring snacks and meet local families.")
                #expect(request.eventURL == "https://tinymeet.app/events/community-picnic")
                #expect(request.audienceType == nil)
                #expect(request.groupID == nil)
                #expect(request.invitedUIDs == nil)
                #expect(request.scheduledAt == scheduledAtString)
                #expect(request.endsAt == endsAtString)
                return created
            }),
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: [])
        )

        let didCreate = await viewModel.createEvent()
        let requests = await recorder.requests

        #expect(didCreate)
        #expect(requests.count == 1)
        #expect(requests.first?.visibility == .public)
        #expect(viewModel.createdEvent?.id == created.id)
        #expect(viewModel.errorMessage == nil)
    }
    // swiftlint:enable function_body_length

    @MainActor
    @Test func publicEventWithoutURLIsInvalidAndExplainsWhy() async throws {
        let viewModel = CreateEventViewModel(
            title: "Community Picnic",
            location: "Town Green",
            scheduledAt: Date(timeIntervalSince1970: 1_778_076_945),
            endsAt: Date(timeIntervalSince1970: 1_778_084_145),
            kidsAge: "4 - 7",
            summary: "Bring snacks and meet local families.",
            eventMode: .public,
            eventURL: "   ",
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: [])
        )

        #expect(viewModel.isFormValid == false)
        #expect(viewModel.validationMessage == "Add an event URL to create a public event.")
    }

    @MainActor
    @Test func createEventReturnsFalseWhenFormIsInvalid() async throws {
        let unexpectedEvent = NearbyEvent(
            title: "Invalid",
            locationName: "Invalid",
            timeDescription: "Invalid",
            ageRange: "Invalid",
            distanceDescription: "Invalid",
            hostName: "Invalid",
            attendeeSummary: "Invalid",
            themeEmoji: "🎉",
            summary: "Invalid",
            visibility: .private
        )

        let viewModel = CreateEventViewModel(
            title: "   ",
            location: "Central Park",
            scheduledAt: Date(),
            kidsAge: "3 - 5",
            eventsRepository: MockCreateEventEventsRepository(createHandler: { _ in
                Issue.record("Repository should not be called for invalid form")
                return unexpectedEvent
            }),
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: [])
        )

        let didCreate = await viewModel.createEvent()

        #expect(didCreate == false)
        #expect(viewModel.createdEvent == nil)
    }
}
