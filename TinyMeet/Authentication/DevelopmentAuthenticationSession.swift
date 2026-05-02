import Foundation

struct DevelopmentAuthenticationSession: Codable, Equatable, Sendable {
    let token: String
    let uid: String
    let email: String
    let displayName: String
    let expiresIn: String

    enum CodingKeys: String, CodingKey {
        case token
        case uid
        case email
        case displayName = "display_name"
        case expiresIn = "expires_in"
    }

    var authorizationHeaderValue: String {
        "Bearer \(token)"
    }
}

enum DevelopmentAuthenticationSessionStorage {
    private static let sessionKey = "auth.development.session"

    static func load(from userDefaults: UserDefaults = .standard) -> DevelopmentAuthenticationSession? {
        guard let data = userDefaults.data(forKey: sessionKey) else {
            return nil
        }

        return try? JSONDecoder().decode(DevelopmentAuthenticationSession.self, from: data)
    }

    static func save(_ session: DevelopmentAuthenticationSession, to userDefaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }

        userDefaults.set(data, forKey: sessionKey)
    }

    static func clear(from userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: sessionKey)
    }
}
