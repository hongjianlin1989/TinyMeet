import Combine
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var identifier = ""
    @Published var password = ""

    var isFormValid: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loginTapped() {
        // Login flow will be implemented here.
    }

    func signUpTapped() {
        // Sign-up flow will be implemented here.
    }
}
