import Combine
import Foundation

@MainActor
final class CreateEventViewModel: ObservableObject {
    enum EventMode: String, CaseIterable, Identifiable {
        case `private` = "Private"
        case `public` = "Public"

        var id: String { rawValue }
    }

    enum JoinVisibility: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case group = "Group"

        var id: String { rawValue }
    }

    @Published var title: String
    @Published var location: String
    @Published var scheduledAt: Date
    @Published var kidsAge: String
    @Published var summary: String
    @Published var eventMode: EventMode
    @Published var eventURL: String
    @Published var joinVisibility: JoinVisibility
    @Published var selectedGroupID: String?
    @Published private(set) var availableGroups: [MeetupGroup] = []
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var isLoadingOptions = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var createdEvent: NearbyEvent?

    private let eventsRepository: EventsRepositoryProtocol
    private let friendsRepository: FriendsRepositoryProtocol
    private let groupsRepository: GroupsRepositoryProtocol

    init(
        title: String = "Playground",
        location: String = "Central Park",
        scheduledAt: Date = CreateEventViewModel.defaultScheduledAt(),
        kidsAge: String = "3 - 5",
        summary: String = "A fun private playdate for local families.",
        eventMode: EventMode = .private,
        eventURL: String = "",
        joinVisibility: JoinVisibility = .friends,
        selectedGroupID: String? = nil,
        eventsRepository: EventsRepositoryProtocol = EventsRepository(),
        friendsRepository: FriendsRepositoryProtocol = FriendsRepository(),
        groupsRepository: GroupsRepositoryProtocol = GroupsRepository()
    ) {
        self.title = title
        self.location = location
        self.scheduledAt = scheduledAt
        self.kidsAge = kidsAge
        self.summary = summary
        self.eventMode = eventMode
        self.eventURL = eventURL
        self.joinVisibility = joinVisibility
        self.selectedGroupID = selectedGroupID
        self.eventsRepository = eventsRepository
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> CreateEventViewModel {
        CreateEventViewModel()
    }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !kidsAge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (eventMode == .public || joinVisibility == .friends || selectedGroupID != nil)
            && (eventMode == .private || !eventURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var isPrivateEvent: Bool {
        eventMode == .private
    }

    var isPublicEvent: Bool {
        eventMode == .public
    }

    var shouldShowGroupPicker: Bool {
        isPrivateEvent && joinVisibility == .group
    }

    var automaticInviteSummary: String {
        guard isPrivateEvent else {
            return "Public events are shared with the community and can include an event URL."
        }

        switch joinVisibility {
        case .friends:
            return friends.isEmpty
                ? "No friends available to auto-invite yet."
                : "All \(friends.count) friends will be added to invited_uids automatically."
        case .group:
            return availableGroups.isEmpty
                ? "No groups available yet."
                : "Choose which group can join this private playdate."
        }
    }

    func loadAudienceOptions() async {
        guard !isLoadingOptions else { return }

        isLoadingOptions = true
        errorMessage = nil
        defer { isLoadingOptions = false }

        var loadErrors: [String] = []

        do {
            friends = try await friendsRepository.fetchFriendProfiles()
        } catch {
            friends = []
            loadErrors.append((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }

        do {
            availableGroups = try await groupsRepository.fetchGroups()
            if selectedGroupID == nil {
                selectedGroupID = availableGroups.first?.id
            }
        } catch {
            availableGroups = []
            loadErrors.append((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }

        if loadErrors.isEmpty == false {
            errorMessage = loadErrors.joined(separator: "\n")
        }
    }

    func createEvent() async -> Bool {
        guard isFormValid, !isSubmitting else { return false }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            createdEvent = try await eventsRepository.createEvent(makeCreateEventRequest())
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    private func makeCreateEventRequest() -> CreateEventRequest {
        if isPublicEvent {
            return CreateEventRequest(
                visibility: .public,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                locationName: location.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: 0,
                longitude: 0,
                ageRange: kidsAge.trimmingCharacters(in: .whitespacesAndNewlines),
                themeEmoji: "🎉",
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                symbolName: nil,
                tintName: nil,
                audienceType: nil,
                groupID: nil,
                invitedUIDs: nil,
                eventURL: eventURL.trimmingCharacters(in: .whitespacesAndNewlines),
                scheduledAt: Self.iso8601Formatter.string(from: scheduledAt)
            )
        }

        return CreateEventRequest(
            visibility: .private,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            locationName: location.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: 0,
            longitude: 0,
            ageRange: kidsAge.trimmingCharacters(in: .whitespacesAndNewlines),
            themeEmoji: "🎉",
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            symbolName: "figure.2.and.child.holdinghands",
            tintName: "mint",
            audienceType: joinVisibility.apiValue,
            groupID: joinVisibility == .group ? selectedGroupID : nil,
            invitedUIDs: joinVisibility == .friends ? friends.map(\.id).sorted() : [],
            eventURL: nil,
            scheduledAt: Self.iso8601Formatter.string(from: scheduledAt)
        )
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private nonisolated static func defaultScheduledAt() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

private extension CreateEventViewModel.JoinVisibility {
    var apiValue: String {
        switch self {
        case .friends:
            return "friends"
        case .group:
            return "group"
        }
    }
}
