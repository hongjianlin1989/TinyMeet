import Combine
import Foundation

@MainActor
final class HomeEventsViewModel: ObservableObject {
    @Published private(set) var events: [NearbyEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedFilter: NearbyEventVisibility

    private let userDefaults: UserDefaults
    private let eventsRepository: EventsRepositoryProtocol

    static func makeDefault() -> HomeEventsViewModel {
        HomeEventsViewModel()
    }

    init(
        userDefaults: UserDefaults = .standard,
        eventsRepository: EventsRepositoryProtocol = EventsRepository()
    ) {
        self.userDefaults = userDefaults
        self.eventsRepository = eventsRepository
        let savedFilter = userDefaults.string(forKey: Self.selectedFilterKey)
        self.selectedFilter = NearbyEventVisibility(rawValue: savedFilter ?? "") ?? .public
    }

    var filteredEvents: [NearbyEvent] {
        events.filter { $0.visibility == selectedFilter }
    }

    func selectFilter(_ filter: NearbyEventVisibility) {
        guard selectedFilter != filter else { return }
        selectedFilter = filter
        userDefaults.set(filter.rawValue, forKey: Self.selectedFilterKey)
    }

    func loadNearbyEvents() async {
        guard events.isEmpty else { return }
        await refreshNearbyEvents()
    }

    func refreshNearbyEvents() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            async let publicEvents = eventsRepository.fetchPublicEvents()
            async let privateEvents = eventsRepository.fetchPrivateEvents()

            let (publicResults, privateResults) = try await (publicEvents, privateEvents)
            events = (publicResults + privateResults)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            events = []
        }
    }

    private static let selectedFilterKey = "home.events.selectedVisibility"

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
