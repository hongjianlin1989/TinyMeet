import Combine
import Foundation

@MainActor
final class DeepLinkHandler: ObservableObject {
    enum Destination: Equatable {
        case login
    }

    @Published var activeDestination: Destination?

    var isShowingLogin: Bool {
        activeDestination == .login
    }

    func handle(_ url: URL) -> Bool {
        guard let destination = Self.destination(for: url) else {
            return false
        }

        activeDestination = destination
        return true
    }

    func presentLogin() {
        activeDestination = .login
    }

    func dismissPresentedDestination() {
        activeDestination = nil
    }

    static func destination(for url: URL) -> Destination? {
        let normalizedScheme = url.scheme?.lowercased()
        let normalizedHost = url.host?.lowercased()
        let normalizedPath = url.path.lowercased()

        if normalizedScheme == "tinymeet" {
            if normalizedHost == "login" || normalizedPath == "/login" {
                return .login
            }

            if normalizedHost == "invite" && hasNonEmptyQueryItem(named: "referrer", in: url) {
                return .login
            }
        }

        if (normalizedScheme == "https" || normalizedScheme == "http"),
           normalizedHost == "tinymeet.app",
           normalizedPath == "/login" {
            return .login
        }

        return nil
    }

    private static func hasNonEmptyQueryItem(named name: String, in url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return false
        }

        return queryItems.contains { item in
            item.name.caseInsensitiveCompare(name) == .orderedSame &&
            !(item.value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }
}
