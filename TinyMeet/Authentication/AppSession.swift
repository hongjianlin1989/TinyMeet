import Combine
import Foundation

@MainActor
final class AppSession: ObservableObject {
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

    func logIn() {
        isLoggedIn = true
    }

    func logOut() {
        isLoggedIn = false
    }

    func updateLanguageCode(_ code: String) {
        selectedLanguageCode = Self.normalizedLanguageCode(from: code)
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
