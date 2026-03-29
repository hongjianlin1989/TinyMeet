import Combine
import Foundation

@MainActor
final class HomeEventsViewModel: ObservableObject {
    @Published private(set) var events: [NearbyEvent] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    static func makeDefault() -> HomeEventsViewModel {
        HomeEventsViewModel()
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

        events = Self.mockEvents
    }

    private static let mockEvents: [NearbyEvent] = [
        NearbyEvent(
            title: "Playground Picnic Crew",
            locationName: "Central Park Playground",
            timeDescription: "Today · 4:00 PM",
            ageRange: "Ages 3-5",
            distanceDescription: "0.4 mi away",
            hostName: "Hosted by Mia",
            attendeeSummary: "8 families going",
            themeEmoji: "🛝",
            summary: "Meet other families for snacks, bubbles, and easy playground fun after nap time."
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
            summary: "Finger painting, sticker crafts, and story time with plenty of room to wiggle."
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
            summary: "A playful beginner-friendly soccer morning for kids who want to run, pass, and laugh."
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
            summary: "Shake instruments, sing favorite songs, and enjoy a bright movement session for toddlers."
        )
    ]
}
