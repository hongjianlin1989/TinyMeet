import Combine
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var identifier = ""
    @Published var password = ""
    @Published var emailLinkEmail = ""
    @Published private(set) var isGoogleSigningIn = false
    @Published private(set) var isSendingSignInLink = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var signInLinkMessage: String?

    private let authenticationRepository: AuthenticationRepositoryProtocol

    init(authenticationRepository: AuthenticationRepositoryProtocol = FirebaseAuthenticationRepository()) {
        self.authenticationRepository = authenticationRepository
    }

    var isFormValid: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSendSignInLink: Bool {
        let trimmedEmail = emailLinkEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedEmail.split(separator: "@")

        return components.count == 2 &&
            !components[0].isEmpty &&
            components[1].contains(".")
    }

    func loginTapped() {
        errorMessage = nil
        // Login flow will be implemented here.
    }

    func signUpTapped() {
        errorMessage = nil
        // Sign-up flow will be implemented here.
    }

    func sendSignInLinkTapped() async -> Bool {
        guard !isSendingSignInLink else { return false }
        guard canSendSignInLink else {
            errorMessage = AuthenticationError.invalidEmail.localizedDescription
            signInLinkMessage = nil
            return false
        }

        isSendingSignInLink = true
        errorMessage = nil
        signInLinkMessage = nil

        defer {
            isSendingSignInLink = false
        }

        do {
            let trimmedEmail = emailLinkEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            try await authenticationRepository.sendSignInLink(to: trimmedEmail)
            signInLinkMessage = "We sent a sign-in link to \(trimmedEmail)."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signInWithGoogleTapped() async -> Bool {
        guard !isGoogleSigningIn else { return false }

        isGoogleSigningIn = true
        errorMessage = nil
        signInLinkMessage = nil

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
