import Combine
import Foundation

// MARK: - Models

enum InterestedEventSource: Equatable {
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

struct InterestedEventRow: Identifiable, Equatable {
    let id: UUID
    let source: InterestedEventSource

    var title: String { source.title }
    var subtitle: String { source.subtitle }
    var visibility: NearbyEventVisibility { source.visibility }
    var symbolName: String { source.symbolName }

    init(id: UUID = UUID(), source: InterestedEventSource) {
        self.id = id
        self.source = source
    }
}

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

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedFilter: Filter = .all
    @Published private(set) var events: [InterestedEventRow] = []

    private let repository: InterestedEventsRepositoryProtocol

    init(repository: InterestedEventsRepositoryProtocol = InterestedEventsRepository()) {
        self.repository = repository
    }

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

        do {
            async let publicRows = repository.fetchInterestedPublicEvents()
            async let privateRows = repository.fetchInterestedPrivateEvents()

            let (publicResults, privateResults) = try await (publicRows, privateRows)
            let rows = publicResults + privateResults
            events = rows.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            events = []
        }
    }

    static func makeDefault() -> InterestedEventsViewModel {
        InterestedEventsViewModel()
    }
}
