import Combine
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var identifier = ""
    @Published var password = ""
    @Published private(set) var isGoogleSigningIn = false
    @Published private(set) var errorMessage: String?

    private let authenticationRepository: AuthenticationRepositoryProtocol

    init(authenticationRepository: AuthenticationRepositoryProtocol = FirebaseAuthenticationRepository()) {
        self.authenticationRepository = authenticationRepository
    }

    var isFormValid: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loginTapped() {
        errorMessage = nil
        // Login flow will be implemented here.
    }

    func signUpTapped() {
        errorMessage = nil
        // Sign-up flow will be implemented here.
    }

    func signInWithGoogleTapped() async -> Bool {
        guard !isGoogleSigningIn else { return false }

        isGoogleSigningIn = true
        errorMessage = nil

        defer {
            isGoogleSigningIn = false
        }

        do {
            try await authenticationRepository.signInWithGoogle()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
