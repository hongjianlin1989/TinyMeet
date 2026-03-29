import Combine
import SwiftUI
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    struct LanguageOption: Identifiable, Equatable {
        let code: String
        let displayNameKey: LocalizedStringKey

        var id: String { code }
    }

    @Published var selectedLanguageCode: String
    @Published var passwordResetMessage: LocalizedStringKey?

    let availableLanguages: [LanguageOption]

    init(
        selectedLanguageCode: String = "en",
        availableLanguages: [LanguageOption] = [
            LanguageOption(code: "en", displayNameKey: "settings.language.english"),
            LanguageOption(code: "zh-Hans", displayNameKey: "settings.language.chinese"),
            LanguageOption(code: "es", displayNameKey: "settings.language.spanish")
        ]
    ) {
        self.availableLanguages = availableLanguages
        self.selectedLanguageCode = Self.normalizedLanguageCode(from: selectedLanguageCode)
    }

    static func makeDefault(selectedLanguageCode: String = "en") -> SettingsViewModel {
        SettingsViewModel(selectedLanguageCode: selectedLanguageCode)
    }

    var selectedLanguageOption: LanguageOption {
        availableLanguages.first(where: { $0.code == selectedLanguageCode }) ?? availableLanguages[0]
    }

    func updateSelectedLanguageCode(_ code: String) {
        selectedLanguageCode = Self.normalizedLanguageCode(from: code)
    }

    func resetPasswordTapped() {
        passwordResetMessage = "settings.password.reset.sent"
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
