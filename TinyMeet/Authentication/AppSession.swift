import Combine
import FirebaseAuth
import Foundation
import GoogleSignIn

@MainActor
final class AppSession: ObservableObject {
    private static let pendingEmailKey = "auth.pendingEmailLinkEmail"
    private let userDefaults: UserDefaults

    @Published var isLoggedIn: Bool
    @Published var selectedLanguageCode: String
    @Published var authErrorMessage: String?

    init(
        isLoggedIn: Bool = false,
        selectedLanguageCode: String = Locale.preferredLanguages.first ?? "en",
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        self.isLoggedIn = isLoggedIn
        self.selectedLanguageCode = Self.normalizedLanguageCode(from: selectedLanguageCode)
        self.authErrorMessage = nil
    }

    var locale: Locale {
        Locale(identifier: selectedLanguageCode)
    }

    func bootstrapAuthentication() async {
        authErrorMessage = nil
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
        authErrorMessage = nil
        refreshAuthenticationState()
    }

    func logOut() async -> Bool {
        authErrorMessage = nil
        GIDSignIn.sharedInstance.signOut()

        do {
            try Auth.auth().signOut()
        } catch {
            authErrorMessage = "We couldn't fully sign you out. Please try again. \(error.localizedDescription)"
            refreshAuthenticationState()
            return false
        }

        userDefaults.removeObject(forKey: Self.pendingEmailKey)
        DevelopmentAuthenticationSessionStorage.clear(from: userDefaults)
        refreshAuthenticationState()
        await bootstrapAuthentication()
        return true
    }

    func updateLanguageCode(_ code: String) {
        selectedLanguageCode = Self.normalizedLanguageCode(from: code)
    }

    private func refreshAuthenticationState() {
        let hasDevelopmentSession = DevelopmentAuthenticationSessionStorage.load(from: userDefaults) != nil

        if let currentUser = Auth.auth().currentUser {
            isLoggedIn = currentUser.isAnonymous == false || hasDevelopmentSession
        } else if hasDevelopmentSession {
            isLoggedIn = true
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
