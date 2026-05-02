import Foundation
import Testing
@testable import TinyMeet

struct AppSessionTests {
    @MainActor
    @Test func logInTreatsStoredDevelopmentSessionAsAuthenticated() async throws {
        let userDefaults = try #require(UserDefaults(suiteName: #function))
        userDefaults.removePersistentDomain(forName: #function)
        defer { userDefaults.removePersistentDomain(forName: #function) }

        DevelopmentAuthenticationSessionStorage.save(
            DevelopmentAuthenticationSession(
                token: "dev-token",
                uid: "dev-uid",
                email: "dev@example.com",
                displayName: "Dev User",
                expiresIn: "7 days"
            ),
            to: userDefaults
        )

        let session = AppSession(userDefaults: userDefaults)
        session.logIn()

        #expect(session.isLoggedIn)
    }
}
