import Combine
import Foundation

@MainActor
final class CreateEventViewModel: ObservableObject {
    enum JoinVisibility: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case group = "Group"
        case `public` = "Public"

        var id: String { rawValue }
    }

    @Published var title: String
    @Published var location: String
    @Published var time: String
    @Published var kidsAge: String
    @Published var joinVisibility: JoinVisibility
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var createdEvent: NearbyEvent?

    private let eventsRepository: EventsRepositoryProtocol

    init(
        title: String = "Playground",
        location: String = "Central Park",
        time: String = "Tomorrow 3pm",
        kidsAge: String = "3 - 5",
        joinVisibility: JoinVisibility = .friends,
        eventsRepository: EventsRepositoryProtocol = EventsRepository()
    ) {
        self.title = title
        self.location = location
        self.time = time
        self.kidsAge = kidsAge
        self.joinVisibility = joinVisibility
        self.eventsRepository = eventsRepository
    }

    static func makeDefault() -> CreateEventViewModel {
        CreateEventViewModel()
    }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !kidsAge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        CreateEventRequest(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            locationName: location.trimmingCharacters(in: .whitespacesAndNewlines),
            timeDescription: time.trimmingCharacters(in: .whitespacesAndNewlines),
            ageRange: kidsAge.trimmingCharacters(in: .whitespacesAndNewlines),
            joinVisibility: joinVisibility.apiValue
        )
    }
}

private extension CreateEventViewModel.JoinVisibility {
    var apiValue: String {
        switch self {
        case .friends:
            return "friends"
        case .group:
            return "group"
        case .public:
            return "public"
        }
    }
}
