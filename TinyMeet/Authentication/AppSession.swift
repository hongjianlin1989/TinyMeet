import Combine
import Foundation

@MainActor
final class AppSession: ObservableObject {
    @Published var isLoggedIn: Bool

    init(isLoggedIn: Bool = false) {
        self.isLoggedIn = isLoggedIn
    }

    func logIn() {
        isLoggedIn = true
    }

    func logOut() {
        isLoggedIn = false
    }
}
