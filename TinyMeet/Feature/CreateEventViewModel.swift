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

    struct ThemeOption: Identifiable, Equatable, Sendable {
        let emoji: String
        let title: String

        var id: String { emoji }
    }

    struct SymbolOption: Identifiable, Equatable, Sendable {
        let symbolName: String
        let title: String

        var id: String { symbolName }
    }

    struct TintOption: Identifiable, Equatable, Sendable {
        let tintName: String
        let title: String

        var id: String { tintName }
    }

    @Published var title: String
    @Published var location: String
    @Published var scheduledAt: Date
    @Published var endsAt: Date
    @Published var kidsAge: String
    @Published var summary: String
    @Published var eventMode: EventMode
    @Published var eventURL: String
    @Published var latitudeText: String
    @Published var longitudeText: String
    @Published var themeEmoji: String
    @Published var symbolName: String
    @Published var tintName: String
    @Published var joinVisibility: JoinVisibility
    @Published var selectedGroupID: String?
    @Published var selectedFriendIDs: Set<String>
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
        endsAt: Date? = nil,
        kidsAge: String = "3 - 5",
        summary: String = "A fun private playdate for local families.",
        eventMode: EventMode = .private,
        eventURL: String = "",
        latitudeText: String = "0",
        longitudeText: String = "0",
        themeEmoji: String = "🎉",
        symbolName: String = "figure.2.and.child.holdinghands",
        tintName: String = "mint",
        joinVisibility: JoinVisibility = .friends,
        selectedGroupID: String? = nil,
        selectedFriendIDs: Set<String> = [],
        eventsRepository: EventsRepositoryProtocol = EventsRepository(),
        friendsRepository: FriendsRepositoryProtocol = FriendsRepository(),
        groupsRepository: GroupsRepositoryProtocol = GroupsRepository()
    ) {
        self.title = title
        self.location = location
        self.scheduledAt = scheduledAt
        self.endsAt = endsAt ?? CreateEventViewModel.defaultEndsAt(from: scheduledAt)
        self.kidsAge = kidsAge
        self.summary = summary
        self.eventMode = eventMode
        self.eventURL = eventURL
        self.latitudeText = latitudeText
        self.longitudeText = longitudeText
        self.themeEmoji = themeEmoji
        self.symbolName = symbolName
        self.tintName = tintName
        self.joinVisibility = joinVisibility
        self.selectedGroupID = selectedGroupID
        self.selectedFriendIDs = selectedFriendIDs
        self.eventsRepository = eventsRepository
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> CreateEventViewModel {
        CreateEventViewModel()
    }

    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a title to continue."
        }

        if location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a location to continue."
        }

        if kidsAge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter the kids age range to continue."
        }

        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a short summary to continue."
        }

        if endsAt <= scheduledAt {
            return "End time must be after begin time."
        }

        if isPublicEvent {
            if eventURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Add an event URL to create a public event."
            }

            return nil
        }

        switch joinVisibility {
        case .friends where selectedFriendIDs.isEmpty:
            return "Select at least one friend for a private playdate."
        case .group where selectedGroupID == nil:
            return "Choose a group for this private playdate."
        default:
            break
        }

        if latitude == nil || longitude == nil {
            return "Private playdates need valid coordinates."
        }

        if themeEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Choose a theme for this private playdate."
        }

        if symbolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Choose a map marker for this private playdate."
        }

        if tintName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Choose a marker color for this private playdate."
        }

        return nil
    }

    var isFormValid: Bool {
        validationMessage == nil
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
                ? "No friends available to invite yet."
                : "\(selectedFriendIDs.count) of \(friends.count) friends will be sent in invited_uids."
        case .group:
            return availableGroups.isEmpty
                ? "No groups available yet."
                : "Choose which group can join this private playdate."
        }
    }

    var availableThemeOptions: [ThemeOption] {
        Self.themeOptions
    }

    var availableSymbolOptions: [SymbolOption] {
        Self.symbolOptions
    }

    var availableTintOptions: [TintOption] {
        Self.tintOptions
    }

    var selectedFriendProfiles: [UserProfile] {
        friends.filter { selectedFriendIDs.contains($0.id) }
    }

    func loadAudienceOptions() async {
        guard !isLoadingOptions else { return }

        isLoadingOptions = true
        errorMessage = nil
        defer { isLoadingOptions = false }

        var loadErrors: [String] = []

        do {
            friends = try await friendsRepository.fetchFriendProfiles()
            let availableFriendIDs = Set(friends.map(\.id))
            if selectedFriendIDs.isEmpty {
                selectedFriendIDs = availableFriendIDs
            } else {
                selectedFriendIDs = selectedFriendIDs.intersection(availableFriendIDs)
            }
        } catch {
            friends = []
            selectedFriendIDs = []
            loadErrors.append((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }

        do {
            availableGroups = try await groupsRepository.fetchGroups()
            if let selectedGroupID, availableGroups.contains(where: { $0.id == selectedGroupID }) == false {
                self.selectedGroupID = nil
            }
            if selectedGroupID == nil {
                selectedGroupID = availableGroups.first?.id
            }
        } catch {
            availableGroups = []
            selectedGroupID = nil
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

    func selectJoinVisibility(_ option: JoinVisibility) {
        joinVisibility = option

        switch option {
        case .friends where selectedFriendIDs.isEmpty:
            selectedFriendIDs = Set(friends.map(\.id))
        default:
            break
        }
    }

    func toggleFriendSelection(_ friend: UserProfile) {
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    func syncEndsAtIfNeeded() {
        guard endsAt <= scheduledAt else { return }
        endsAt = Self.defaultEndsAt(from: scheduledAt)
    }

    private func makeCreateEventRequest() -> CreateEventRequest {
        if isPublicEvent {
            return CreateEventRequest(
                visibility: .public,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                locationName: location.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitude ?? 0,
                longitude: longitude ?? 0,
                ageRange: kidsAge.trimmingCharacters(in: .whitespacesAndNewlines),
                themeEmoji: themeEmoji.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                symbolName: nil,
                tintName: nil,
                audienceType: nil,
                groupID: nil,
                invitedUIDs: nil,
                eventURL: eventURL.trimmingCharacters(in: .whitespacesAndNewlines),
                scheduledAt: Self.iso8601Formatter.string(from: scheduledAt),
                endsAt: Self.iso8601Formatter.string(from: endsAt)
            )
        }

        return CreateEventRequest(
            visibility: .private,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            locationName: location.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            ageRange: kidsAge.trimmingCharacters(in: .whitespacesAndNewlines),
            themeEmoji: themeEmoji.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            symbolName: symbolName.trimmingCharacters(in: .whitespacesAndNewlines),
            tintName: tintName.trimmingCharacters(in: .whitespacesAndNewlines),
            audienceType: joinVisibility.apiValue,
            groupID: joinVisibility == .group ? selectedGroupID : nil,
            invitedUIDs: joinVisibility == .friends ? selectedFriendIDs.sorted() : [],
            eventURL: nil,
            scheduledAt: Self.iso8601Formatter.string(from: scheduledAt),
            endsAt: Self.iso8601Formatter.string(from: endsAt)
        )
    }

    private var latitude: Double? {
        Self.parseCoordinate(latitudeText, validRange: -90...90)
    }

    private var longitude: Double? {
        Self.parseCoordinate(longitudeText, validRange: -180...180)
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

    private nonisolated static func defaultEndsAt(from scheduledAt: Date) -> Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: scheduledAt) ?? scheduledAt.addingTimeInterval(7200)
    }

    private nonisolated static func parseCoordinate(_ value: String, validRange: ClosedRange<Double>) -> Double? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let coordinate = Double(trimmedValue), validRange.contains(coordinate) else {
            return nil
        }

        return coordinate
    }

    private nonisolated static let themeOptions: [ThemeOption] = [
        ThemeOption(emoji: "🎉", title: "Celebration"),
        ThemeOption(emoji: "🛝", title: "Playground"),
        ThemeOption(emoji: "☕️", title: "Coffee Chat"),
        ThemeOption(emoji: "🧺", title: "Picnic"),
        ThemeOption(emoji: "📚", title: "Story Time")
    ]

    private nonisolated static let symbolOptions: [SymbolOption] = [
        SymbolOption(symbolName: "figure.2.and.child.holdinghands", title: "Playdate"),
        SymbolOption(symbolName: "balloon.2.fill", title: "Party"),
        SymbolOption(symbolName: "figure.play", title: "Active"),
        SymbolOption(symbolName: "book.closed.fill", title: "Learning"),
        SymbolOption(symbolName: "leaf.fill", title: "Outdoors")
    ]

    private nonisolated static let tintOptions: [TintOption] = [
        TintOption(tintName: "mint", title: "Mint"),
        TintOption(tintName: "orange", title: "Peach"),
        TintOption(tintName: "pink", title: "Pink")
    ]
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
