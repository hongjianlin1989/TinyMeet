import Combine
import FirebaseAuth
import Foundation
import GoogleSignIn

@MainActor
final class AppSession: ObservableObject {
    private static let pendingEmailKey = "auth.pendingEmailLinkEmail"

    @Published var isLoggedIn: Bool
    @Published var selectedLanguageCode: String

    init(
        isLoggedIn: Bool = false,
        selectedLanguageCode: String = Locale.preferredLanguages.first ?? "en"
    ) {
        self.isLoggedIn = isLoggedIn
        self.selectedLanguageCode = Self.normalizedLanguageCode(from: selectedLanguageCode)
    }

    var locale: Locale {
        Locale(identifier: selectedLanguageCode)
    }

    func bootstrapAuthentication() async {
        refreshAuthenticationState()

        guard Auth.auth().currentUser == nil else {
            return
        }

        do {
            _ = try await Auth.auth().tinyMeetSignInAnonymously()
        } catch {
            print("Failed to create anonymous Firebase session: \(error)")
        }

        refreshAuthenticationState()
    }

    func logIn() {
        refreshAuthenticationState()
    }

    func logOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: Self.pendingEmailKey)
        isLoggedIn = false

        Task { @MainActor in
            await bootstrapAuthentication()
        }
    }

    func updateLanguageCode(_ code: String) {
        selectedLanguageCode = Self.normalizedLanguageCode(from: code)
    }

    private func refreshAuthenticationState() {
        if let currentUser = Auth.auth().currentUser {
            isLoggedIn = currentUser.isAnonymous == false
        } else {
            isLoggedIn = false
        }
    }

    private static func normalizedLanguageCode(from code: String) -> String {
        let normalizedCode = code.lowercased()

        if normalizedCode.hasPrefix("zh") {
            return "zh-Hans"
        }

        if normalizedCode.hasPrefix("es") {
            return "es"
        }

        return "en"
    }
}

private extension Auth {
    func tinyMeetSignInAnonymously() async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result else {
                    continuation.resume(throwing: AuthenticationSessionError.missingAuthResult)
                    return
                }

                continuation.resume(returning: result)
            }
        }
    }
}

private enum AuthenticationSessionError: LocalizedError {
    case missingAuthResult

    var errorDescription: String? {
        switch self {
        case .missingAuthResult:
            return "Firebase did not return an authentication session."
        }
    }
}
