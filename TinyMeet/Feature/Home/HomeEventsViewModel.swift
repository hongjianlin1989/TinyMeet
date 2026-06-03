import Combine
import Foundation

@MainActor
final class HomeEventsViewModel: ObservableObject {
    @Published private(set) var events: [NearbyEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedFilter: NearbyEventVisibility
    @Published private(set) var selectedCategories: [NearbyEventCategory]
    @Published private(set) var selectedAgeGroups: [NearbyEventAgeGroup]
    @Published private(set) var publicFeedNoticeMessage: String?
    @Published private(set) var interestUpdateIDs: Set<UUID> = []

    private let userDefaults: UserDefaults
    private let eventsRepository: EventsRepositoryProtocol
    private let interestedEventsRepository: InterestedEventsRepositoryProtocol
    private let postalCodeProvider: HomePostalCodeProviding
    private var needsRefreshAfterCurrentLoad = false

    static func makeDefault() -> HomeEventsViewModel {
        HomeEventsViewModel()
    }

    init(
        userDefaults: UserDefaults = .standard,
        eventsRepository: EventsRepositoryProtocol = EventsRepository(),
        interestedEventsRepository: InterestedEventsRepositoryProtocol = InterestedEventsRepository(),
        postalCodeProvider: HomePostalCodeProviding? = nil
    ) {
        self.userDefaults = userDefaults
        self.eventsRepository = eventsRepository
        self.interestedEventsRepository = interestedEventsRepository
        self.postalCodeProvider = postalCodeProvider ?? HomePostalCodeProvider(userDefaults: userDefaults)
        let savedFilter = NearbyEventVisibility(rawValue: userDefaults.string(forKey: Self.selectedFilterKey) ?? "")
        self.selectedFilter = savedFilter ?? .private
        self.selectedCategories = Self.savedValues(
            forKey: Self.selectedCategoriesKey,
            in: userDefaults,
            allCases: NearbyEventCategory.allCases
        )
        self.selectedAgeGroups = Self.savedValues(
            forKey: Self.selectedAgeGroupsKey,
            in: userDefaults,
            allCases: NearbyEventAgeGroup.allCases
        )
    }

    var filteredEvents: [NearbyEvent] {
        events.filter { $0.visibility == selectedFilter }
    }

    var hasPublicFilters: Bool {
        selectedCategories.isEmpty == false || selectedAgeGroups.isEmpty == false
    }

    func selectFilter(_ filter: NearbyEventVisibility) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        userDefaults.set(filter.rawValue, forKey: Self.selectedFilterKey)
    }

    func toggleCategory(_ category: NearbyEventCategory) async {
        selectedCategories = toggleSelection(
            selectedCategories,
            value: category,
            allCases: NearbyEventCategory.allCases
        )
        userDefaults.set(selectedCategories.map(\.rawValue), forKey: Self.selectedCategoriesKey)
        await refreshNearbyEvents()
    }

    func toggleAgeGroup(_ ageGroup: NearbyEventAgeGroup) async {
        selectedAgeGroups = toggleSelection(
            selectedAgeGroups,
            value: ageGroup,
            allCases: NearbyEventAgeGroup.allCases
        )
        userDefaults.set(selectedAgeGroups.map(\.rawValue), forKey: Self.selectedAgeGroupsKey)
        await refreshNearbyEvents()
    }

    func clearPublicFilters() async {
        guard hasPublicFilters else { return }
        selectedCategories = []
        selectedAgeGroups = []
        userDefaults.removeObject(forKey: Self.selectedCategoriesKey)
        userDefaults.removeObject(forKey: Self.selectedAgeGroupsKey)
        await refreshNearbyEvents()
    }

    func loadNearbyEvents() async {
        guard events.isEmpty else { return }
        await refreshNearbyEvents()
    }

    func refreshNearbyEvents() async {
        guard isLoading == false else {
            needsRefreshAfterCurrentLoad = true
            return
        }

        repeat {
            needsRefreshAfterCurrentLoad = false
            isLoading = true
            errorMessage = nil

            do {
                async let publicEvents = eventsRepository.fetchPublicEvents()
                async let privateEvents = eventsRepository.fetchPrivateEvents()
                async let interestedEvents = interestedEventsRepository.fetchInterestedEvents()

                let postalCode = await postalCodeProvider.currentPostalCode()
                let publicFeedNoticeMessage = postalCode == nil
                    ? "Allow location access to load nearby external events."
                    : nil
                let (publicResults, privateResults, interestedRows) = try await (
                    publicEvents,
                    privateEvents,
                    interestedEvents
                )
                let externalResults: [NearbyEvent]

                if let postalCode {
                    let externalResponse = try await eventsRepository.fetchUnifiedFeed(
                        types: ["external"],
                        categories: selectedCategories.map(\.rawValue),
                        ageGroups: selectedAgeGroups.map(\.rawValue),
                        postalCode: postalCode,
                        cursor: nil
                    )
                    externalResults = externalResponse.events.filter { $0.visibility == .external }
                } else {
                    externalResults = []
                }

                let interestedIDSet = Set(interestedRows.map(\.id))
                self.events = (privateResults + publicResults + externalResults).map { event in
                    var event = event
                    event.isInterested = event.isInterested || interestedIDSet.contains(event.id)
                    return event
                }
                self.publicFeedNoticeMessage = publicFeedNoticeMessage
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                events = []
                publicFeedNoticeMessage = nil
            }

            isLoading = false
        } while needsRefreshAfterCurrentLoad
    }

    func isUpdatingInterest(for eventID: UUID) -> Bool {
        interestUpdateIDs.contains(eventID)
    }

    func toggleInterest(for eventID: UUID) async {
        guard !interestUpdateIDs.contains(eventID),
              let index = events.firstIndex(where: { $0.id == eventID }) else {
            return
        }

        let previousValue = events[index].isInterested
        let newValue = !previousValue

        interestUpdateIDs.insert(eventID)
        events[index].isInterested = newValue

        defer { interestUpdateIDs.remove(eventID) }

        do {
            try await interestedEventsRepository.setInterested(newValue, event: events[index])
        } catch {
            events[index].isInterested = previousValue
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func event(for eventID: UUID) -> NearbyEvent? {
        events.first(where: { $0.id == eventID })
    }

    private static let selectedFilterKey = "home.events.selectedVisibility"
    private static let selectedCategoriesKey = "home.events.selectedCategories"
    private static let selectedAgeGroupsKey = "home.events.selectedAgeGroups"

    private static func savedValues<T: RawRepresentable & Sendable>(
        forKey key: String,
        in userDefaults: UserDefaults,
        allCases: [T]
    ) -> [T] where T.RawValue == String {
        let savedValues = Set(userDefaults.stringArray(forKey: key) ?? [])
        return allCases.filter { savedValues.contains($0.rawValue) }
    }

    private func toggleSelection<T: RawRepresentable & Sendable>(
        _ currentValues: [T],
        value: T,
        allCases: [T]
    ) -> [T] where T.RawValue == String {
        var selectedValues = Set(currentValues.map(\.rawValue))

        if selectedValues.contains(value.rawValue) {
            selectedValues.remove(value.rawValue)
        } else {
            selectedValues.insert(value.rawValue)
        }

        return allCases.filter { selectedValues.contains($0.rawValue) }
    }

    static let mockEvents: [NearbyEvent] = [
        NearbyEvent(
            title: "Playground Picnic Crew",
            locationName: "Central Park Playground",
            timeDescription: "Today · 4:00 PM",
            ageRange: "Ages 3-5",
            distanceDescription: "0.4 mi away",
            hostName: "Hosted by Mia",
            attendeeSummary: "8 families going",
            themeEmoji: "🛝",
            summary: "Meet other families for snacks, bubbles, and easy playground fun after nap time.",
            eventUrl: "https://tinymeet.app/events/playground-picnic-crew",
            visibility: .public
        ),
        NearbyEvent(
            title: "Little Artists Meet-Up",
            locationName: "Sunny Side Community Center",
            timeDescription: "Tomorrow · 10:30 AM",
            ageRange: "Ages 4-7",
            distanceDescription: "0.8 mi away",
            hostName: "Hosted by Noah",
            attendeeSummary: "12 kids signed up",
            themeEmoji: "🎨",
            summary: "Finger painting, sticker crafts, and story time with plenty of room to wiggle.",
            eventUrl: "https://tinymeet.app/events/little-artists-meet-up",
            visibility: .public
        ),
        NearbyEvent(
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate for nearby families who already know one another.",
            visibility: .private
        ),
        NearbyEvent(
            title: "Mini Soccer Kickaround",
            locationName: "Maple Field",
            timeDescription: "Saturday · 9:00 AM",
            ageRange: "Ages 5-8",
            distanceDescription: "1.1 mi away",
            hostName: "Hosted by Ava",
            attendeeSummary: "6 teammates ready",
            themeEmoji: "⚽️",
            summary: "A playful beginner-friendly soccer morning for kids who want to run, pass, and laugh.",
            eventUrl: "https://tinymeet.app/events/mini-soccer-kickaround",
            visibility: .public
        ),
        NearbyEvent(
            title: "Music & Wiggles Circle",
            locationName: "Rainbow Library Room",
            timeDescription: "Sunday · 11:00 AM",
            ageRange: "Ages 2-4",
            distanceDescription: "1.5 mi away",
            hostName: "Hosted by Ethan",
            attendeeSummary: "10 little dancers",
            themeEmoji: "🎵",
            summary: "Shake instruments, sing favorite songs, and enjoy a bright movement session for toddlers.",
            eventUrl: "https://tinymeet.app/events/music-and-wiggles-circle",
            visibility: .public
        ),
        NearbyEvent(
            title: "Pajama Story Snuggle",
            locationName: "Willow House Living Room",
            timeDescription: "Sunday · 6:30 PM",
            ageRange: "Ages 3-6",
            distanceDescription: "0.9 mi away",
            hostName: "Hosted by Sofia",
            attendeeSummary: "Private group · 3 families",
            themeEmoji: "📚",
            summary: "An invite-only wind-down with bedtime stories, soft music, and cocoa for little ones.",
            visibility: .private
        )
    ]
}
