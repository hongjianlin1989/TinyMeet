import Foundation
import Testing
@testable import TinyMeet

struct CreateEventViewModelTests {
    struct MockEventsRepository: EventsRepositoryProtocol {
        let createHandler: @Sendable (CreateEventRequest) async throws -> NearbyEvent

        func fetchPublicEvents() async throws -> [NearbyEvent] { [] }
        func fetchPrivateEvents() async throws -> [NearbyEvent] { [] }
        func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
            try await createHandler(request)
        }
    }

    struct MockFriendsRepository: FriendsRepositoryProtocol {
        let friends: [UserProfile]

        func fetchFriendProfiles() async throws -> [UserProfile] { friends }
        func fetchFriendRequests() async throws -> [UserProfile] { [] }
        func acceptFriendRequest(_ request: UserProfile) async throws { }
        func rejectFriendRequest(_ request: UserProfile) async throws { }
        func addFriend(_ profile: UserProfile) async throws { }
        func removeFriend(_ profile: UserProfile) async throws { }
    }

    struct MockGroupsRepository: GroupsRepositoryProtocol {
        let groups: [MeetupGroup]

        func fetchGroups() async throws -> [MeetupGroup] { groups }
        func createGroup(_ request: CreateGroupRequest) async throws { }
        func fetchGroupDetail(groupID: String) async throws -> GroupDetail { GroupDetail.mockDetails[0] }
        func deleteGroup(groupID: String) async throws { }
        func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
        func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws { }
        func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool { true }
    }

    actor CreateEventRequestRecorder {
        private(set) var requests: [CreateEventRequest] = []

        func record(_ request: CreateEventRequest) {
            requests.append(request)
        }
    }

    @MainActor
    @Test func createFriendsEventSubmitsAllFriendUIDsAndStoresCreatedEvent() async throws {
        let created = NearbyEvent(
            title: "Playground Party",
            locationName: "Central Park",
            timeDescription: "May 4 · 3:00 PM",
            ageRange: "3 - 5",
            distanceDescription: "Just created",
            hostName: "Hosted by You",
            attendeeSummary: "Private friends event",
            themeEmoji: "🎉",
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
        let scheduledAt = ISO8601DateFormatter().date(from: "2026-05-03T13:56:44Z") ?? Date()

        let viewModel = CreateEventViewModel(
            title: "Playground Party",
            location: "Central Park",
            scheduledAt: scheduledAt,
            kidsAge: "3 - 5",
            summary: "A fun private playdate for local families.",
            eventMode: .private,
            joinVisibility: .friends,
            eventsRepository: MockEventsRepository(createHandler: { request in
                #expect(request.visibility == .private)
                #expect(request.title == "Playground Party")
                #expect(request.locationName == "Central Park")
                #expect(request.latitude == 0)
                #expect(request.longitude == 0)
                #expect(request.ageRange == "3 - 5")
                #expect(request.audienceType == "friends")
                #expect(request.groupID == nil)
                #expect(request.invitedUIDs == ["friend-amy", "friend-noah"])
                #expect(request.eventURL == nil)
                return created
            }),
            friendsRepository: MockFriendsRepository(friends: [amy, noah]),
            groupsRepository: MockGroupsRepository(groups: [])
        )

        await viewModel.loadAudienceOptions()

        let didCreate = await viewModel.createEvent()
        #expect(didCreate)
        #expect(viewModel.createdEvent?.id == created.id)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func createGroupEventRequiresSelectedGroupAndSubmitsGroupID() async throws {
        let group = MeetupGroup(
            id: "group-123",
            name: "Weekend Hikers",
            location: "Palo Alto",
            memberCount: 0,
            summary: "Easy weekend hikes"
        )
        let scheduledAt = ISO8601DateFormatter().date(from: "2026-05-03T13:56:44Z") ?? Date()
        let viewModel = CreateEventViewModel(
            title: "Playground Party",
            location: "Central Park",
            scheduledAt: scheduledAt,
            kidsAge: "3 - 5",
            summary: "Private group playdate.",
            eventMode: .private,
            joinVisibility: .group,
            eventsRepository: MockEventsRepository(createHandler: { request in
                #expect(request.visibility == .private)
                #expect(request.audienceType == "group")
                #expect(request.groupID == "group-123")
                #expect(request.invitedUIDs == [])
                #expect(request.eventURL == nil)
                return await MainActor.run {
                    request.toNearbyEvent()
                }
            }),
            friendsRepository: MockFriendsRepository(friends: []),
            groupsRepository: MockGroupsRepository(groups: [group])
        )

        await viewModel.loadAudienceOptions()

        #expect(viewModel.shouldShowGroupPicker)
        #expect(viewModel.selectedGroupID == "group-123")

        let didCreate = await viewModel.createEvent()
        #expect(didCreate)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func createPublicEventUsesPublicPayloadAndDoesNotRequireAudienceSelection() async throws {
        let created = NearbyEvent(
            title: "Community Picnic",
            locationName: "Town Green",
            timeDescription: "May 3 · 2:15 PM",
            ageRange: "4 - 7",
            distanceDescription: "Community",
            hostName: "Hosted by You",
            attendeeSummary: "New public event",
            themeEmoji: "🎉",
            summary: "Bring snacks and meet local families.",
            eventUrl: "https://tinymeet.app/events/community-picnic",
            visibility: .public
        )
        let scheduledAt = ISO8601DateFormatter().date(from: "2026-05-03T14:15:45Z") ?? Date()
        let recorder = CreateEventRequestRecorder()

        let viewModel = CreateEventViewModel(
            title: "Community Picnic",
            location: "Town Green",
            scheduledAt: scheduledAt,
            kidsAge: "4 - 7",
            summary: "Bring snacks and meet local families.",
            eventMode: .public,
            eventURL: "https://tinymeet.app/events/community-picnic",
            joinVisibility: .friends,
            eventsRepository: MockEventsRepository(createHandler: { request in
                await recorder.record(request)
                #expect(request.visibility == .public)
                #expect(request.title == "Community Picnic")
                #expect(request.locationName == "Town Green")
                #expect(request.eventURL == "https://tinymeet.app/events/community-picnic")
                #expect(request.audienceType == nil)
                #expect(request.groupID == nil)
                #expect(request.invitedUIDs == nil)
                return created
            }),
            friendsRepository: MockFriendsRepository(friends: []),
            groupsRepository: MockGroupsRepository(groups: [])
        )

        let didCreate = await viewModel.createEvent()
        let requests = await recorder.requests

        #expect(didCreate)
        #expect(requests.count == 1)
        #expect(requests.first?.visibility == .public)
        #expect(viewModel.createdEvent?.id == created.id)
        #expect(viewModel.errorMessage == nil)
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
            eventsRepository: MockEventsRepository(createHandler: { _ in
                Issue.record("Repository should not be called for invalid form")
                return unexpectedEvent
            }),
            friendsRepository: MockFriendsRepository(friends: []),
            groupsRepository: MockGroupsRepository(groups: [])
        )

        let didCreate = await viewModel.createEvent()

        #expect(didCreate == false)
        #expect(viewModel.createdEvent == nil)
    }
}
