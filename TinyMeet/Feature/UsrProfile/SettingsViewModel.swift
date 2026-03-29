import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: String
    @Published var passwordResetMessage: String?

    let availableLanguages: [String]

    init(
        selectedLanguage: String = "English",
        availableLanguages: [String] = ["English", "中文", "Español"]
    ) {
        self.selectedLanguage = selectedLanguage
        self.availableLanguages = availableLanguages
    }

    static func makeDefault() -> SettingsViewModel {
        SettingsViewModel()
    }

    func resetPasswordTapped() {
        passwordResetMessage = "Password reset link sent."
    }
}
