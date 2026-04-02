import Combine
import Foundation

@MainActor
final class InterestedEventsViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case `public`
        case `private`

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .public:
                return "Public"
            case .private:
                return "Private"
            }
        }
    }

    struct InterestedEventRow: Identifiable, Equatable {
        enum Source: Equatable {
            case nearby(NearbyEvent)
            case privateMap(PrivateEventMapItem)

            var visibility: NearbyEventVisibility {
                switch self {
                case .nearby(let event):
                    return event.visibility
                case .privateMap:
                    return .private
                }
            }

            var title: String {
                switch self {
                case .nearby(let event):
                    return event.title
                case .privateMap(let event):
                    return event.title
                }
            }

            var subtitle: String {
                switch self {
                case .nearby(let event):
                    return "\(event.locationName) · \(event.timeDescription)"
                case .privateMap(let event):
                    return event.subtitle
                }
            }

            var symbolName: String {
                switch self {
                case .nearby:
                    return "calendar"
                case .privateMap(let event):
                    return event.symbolName
                }
            }
        }

        let id: UUID
        let source: Source

        var title: String { source.title }
        var subtitle: String { source.subtitle }
        var visibility: NearbyEventVisibility { source.visibility }
        var symbolName: String { source.symbolName }

        init(id: UUID = UUID(), source: Source) {
            self.id = id
            self.source = source
        }
    }

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedFilter: Filter = .all
    @Published private(set) var events: [InterestedEventRow] = []

    var filteredEvents: [InterestedEventRow] {
        switch selectedFilter {
        case .all:
            return events
        case .public:
            return events.filter { $0.visibility == .public }
        case .private:
            return events.filter { $0.visibility == .private }
        }
    }

    func loadInterestedEvents() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // TODO: Replace mocks with real "interested" fetch once backend endpoints exist.
        // For now we merge the existing mock sources used elsewhere in the app.
        let nearbyEvents = HomeEventsViewModel.mockEventsForInterestedList()
        let privateEvents = PrivateEventMapItem.mockItems

        var rows: [InterestedEventRow] = []
        rows.append(contentsOf: nearbyEvents.map { InterestedEventRow(source: .nearby($0)) })
        rows.append(contentsOf: privateEvents.map { InterestedEventRow(source: .privateMap($0)) })

        // Stable-ish ordering.
        events = rows.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    static func makeDefault() -> InterestedEventsViewModel {
        InterestedEventsViewModel()
    }
}

private extension HomeEventsViewModel {
    /// We keep the Interested Events list decoupled from the Home screen state by exposing a lightweight mock builder.
    static func mockEventsForInterestedList() -> [NearbyEvent] {
        // If HomeEventsViewModel ever stops being mock-backed, we can remove this and plug into a repository.
        return [
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
                visibility: .public
            ),
            NearbyEvent(
                title: "Private Craft Hour",
                locationName: "Community Center",
                timeDescription: "Tomorrow · 11:00 AM",
                ageRange: "Ages 4-7",
                distanceDescription: "1.2 mi away",
                hostName: "Hosted by Alex",
                attendeeSummary: "5 families going",
                themeEmoji: "🎨",
                summary: "A smaller invite-only craft circle with open play afterward.",
                visibility: .private
            )
        ]
    }
}
