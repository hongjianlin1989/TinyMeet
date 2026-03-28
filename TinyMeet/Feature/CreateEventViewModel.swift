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

    init(
        title: String = "Playground",
        location: String = "Central Park",
        time: String = "Tomorrow 3pm",
        kidsAge: String = "3 - 5",
        joinVisibility: JoinVisibility = .friends
    ) {
        self.title = title
        self.location = location
        self.time = time
        self.kidsAge = kidsAge
        self.joinVisibility = joinVisibility
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

    func createEvent() {
        // Hook for future repository/network integration.
    }
}
