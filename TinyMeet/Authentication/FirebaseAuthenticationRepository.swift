import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

protocol AuthenticationRepositoryProtocol: Sendable {
    @MainActor
    func signInWithGoogle() async throws
}

enum AuthenticationError: LocalizedError {
    case missingGoogleClientID
    case missingPresentingViewController
    case missingGoogleIDToken

    var errorDescription: String? {
        switch self {
        case .missingGoogleClientID:
            return "Google Sign-In is not configured yet. Please update GoogleService-Info.plist with a CLIENT_ID and REVERSED_CLIENT_ID from Firebase Console."
        case .missingPresentingViewController:
            return "Unable to present Google Sign-In right now. Please try again."
        case .missingGoogleIDToken:
            return "Google Sign-In completed without an ID token. Please try again."
        }
    }
}

struct FirebaseAuthenticationRepository: AuthenticationRepositoryProtocol {
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
