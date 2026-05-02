import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

protocol AuthenticationRepositoryProtocol: Sendable {
    @MainActor
    func signInWithGoogle() async throws

    func sendSignInLink(to email: String) async throws
    func signInWithDevelopmentEmail(_ email: String) async throws -> DevelopmentAuthenticationSession
}

enum AuthenticationError: LocalizedError {
    case missingGoogleClientID
    case missingPresentingViewController
    case missingGoogleIDToken
    case invalidEmail
    case missingEmailLinkURL

    var errorDescription: String? {
        switch self {
        case .missingGoogleClientID:
            return "Google Sign-In is not configured yet. Please update GoogleService-Info.plist with a CLIENT_ID and REVERSED_CLIENT_ID from Firebase Console."
        case .missingPresentingViewController:
            return "Unable to present Google Sign-In right now. Please try again."
        case .missingGoogleIDToken:
            return "Google Sign-In completed without an ID token. Please try again."
        case .invalidEmail:
            return "Enter a valid email address."
        case .missingEmailLinkURL:
            return "Email link sign-in is not configured yet. Please make sure Firebase has a valid project ID and authorized email link domain."
        }
    }
}

struct FirebaseAuthenticationRepository: AuthenticationRepositoryProtocol {
    private static let pendingEmailKey = "auth.pendingEmailLinkEmail"
    private let networkManager: NetworkManaging

    init(networkManager: NetworkManaging = NetworkManager()) {
        self.networkManager = networkManager
    }

    @MainActor
    func signInWithGoogle() async throws {
        guard let clientID = Self.googleClientID else {
            throw AuthenticationError.missingGoogleClientID
        }

        guard let presentingViewController = UIApplication.shared.topViewController else {
            throw AuthenticationError.missingPresentingViewController
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthenticationError.missingGoogleIDToken
        }

        let accessToken = signInResult.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        _ = try await Auth.auth().signIn(with: credential)
        DevelopmentAuthenticationSessionStorage.clear()
        try await syncBackendUserProfile()
    }

    func sendSignInLink(to email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Self.isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        let actionCodeSettings = try Self.makeEmailActionCodeSettings()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().sendSignInLink(toEmail: trimmedEmail, actionCodeSettings: actionCodeSettings) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    UserDefaults.standard.set(trimmedEmail, forKey: Self.pendingEmailKey)
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func signInWithDevelopmentEmail(_ email: String) async throws -> DevelopmentAuthenticationSession {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard Self.isValidEmail(trimmedEmail) else {
            throw AuthenticationError.invalidEmail
        }

        let request = try DevelopmentAuthenticationUrlRequest.token(email: trimmedEmail).asURLRequest()
        let session: DevelopmentAuthenticationSession = try await networkManager.perform(request)
        DevelopmentAuthenticationSessionStorage.save(session)
        return session
    }

    private static var googleClientID: String? {
        if let firebaseClientID = FirebaseApp.app()?.options.clientID, !firebaseClientID.isEmpty {
            return firebaseClientID
        }

        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let clientID = plist["CLIENT_ID"] as? String,
              !clientID.isEmpty else {
            return nil
        }

        return clientID
    }

    private static func makeEmailActionCodeSettings() throws -> ActionCodeSettings {
        guard let url = emailLinkURL else {
            throw AuthenticationError.missingEmailLinkURL
        }

        let settings = ActionCodeSettings()
        settings.url = url
        settings.handleCodeInApp = true

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            settings.setIOSBundleID(bundleIdentifier)
        }

        return settings
    }

    private static var emailLinkURL: URL? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: "FirebaseEmailLinkURL") as? String,
           let configuredURL = URL(string: infoValue),
           !infoValue.isEmpty {
            return configuredURL
        }

        let projectID = FirebaseApp.app()?.options.projectID ?? googleServiceValue(for: "PROJECT_ID")

        guard let projectID, !projectID.isEmpty else {
            return nil
        }

        return URL(string: "https://\(projectID).firebaseapp.com/finishSignIn")
    }

    private static func googleServiceValue(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String,
              !value.isEmpty else {
            return nil
        }

        return value
    }

    private static func isValidEmail(_ value: String) -> Bool {
        let parts = value.split(separator: "@")
        guard parts.count == 2,
              !parts[0].isEmpty,
              parts[1].contains(".") else {
            return false
        }

        return true
    }

    private func syncBackendUserProfile() async throws {
        let url = ApiConfig.baseURL.appending(path: "/api/v1/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let _: UserProfileResponse = try await networkManager.perform(request)
    }
}

private extension UIApplication {
    var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    var topViewController: UIViewController? {
        guard let rootViewController = activeKeyWindow?.rootViewController else {
            return nil
        }

        return Self.topViewController(from: rootViewController)
    }

    static func topViewController(from controller: UIViewController) -> UIViewController {
        if let navigationController = controller as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topViewController(from: visibleViewController)
        }

        if let tabBarController = controller as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(from: selectedViewController)
        }

        if let presentedViewController = controller.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return controller
    }
}
