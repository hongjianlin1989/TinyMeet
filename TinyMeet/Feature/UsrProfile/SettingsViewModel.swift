import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    struct LanguageOption: Identifiable, Equatable {
        let code: String
        let displayNameKey: LocalizedStringKey

        var id: String { code }
    }

    @Published var selectedLanguageCode: String
    @Published var selectedLocationSharingPreference: LocationSharingPreference
    @Published var passwordResetMessage: LocalizedStringKey?

    let availableLanguages: [LanguageOption]
    let availableLocationSharingPreferences: [LocationSharingPreference]

    private var locationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol

    init(
        selectedLanguageCode: String = "en",
        locationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol? = nil,
        availableLanguages: [LanguageOption] = [
            LanguageOption(code: "en", displayNameKey: "settings.language.english"),
            LanguageOption(code: "zh-Hans", displayNameKey: "settings.language.chinese"),
            LanguageOption(code: "es", displayNameKey: "settings.language.spanish")
        ],
        availableLocationSharingPreferences: [LocationSharingPreference] = LocationSharingPreference.allCases
    ) {
        let locationSharingPreferencesStore = locationSharingPreferencesStore ?? UserDefaultsLocationSharingPreferencesStore.shared
        self.locationSharingPreferencesStore = locationSharingPreferencesStore
        self.availableLanguages = availableLanguages
        self.availableLocationSharingPreferences = availableLocationSharingPreferences
        self.selectedLanguageCode = Self.normalizedLanguageCode(from: selectedLanguageCode)
        self.selectedLocationSharingPreference = availableLocationSharingPreferences.first(where: {
            $0 == locationSharingPreferencesStore.selectedPreference
        }) ?? availableLocationSharingPreferences[0]
    }

    static func makeDefault(selectedLanguageCode: String = "en") -> SettingsViewModel {
        SettingsViewModel(selectedLanguageCode: selectedLanguageCode)
    }

    var selectedLanguageOption: LanguageOption {
        availableLanguages.first(where: { $0.code == selectedLanguageCode }) ?? availableLanguages[0]
    }

    var selectedLocationSharingOption: LocationSharingPreference {
        availableLocationSharingPreferences.first(where: { $0 == selectedLocationSharingPreference }) ?? availableLocationSharingPreferences[0]
    }

    func updateSelectedLanguageCode(_ code: String) {
        selectedLanguageCode = Self.normalizedLanguageCode(from: code)
    }

    func refreshSelectedLocationSharingPreference() {
        selectedLocationSharingPreference = resolvedLocationSharingPreference(from: locationSharingPreferencesStore.selectedPreference)
    }

    func updateSelectedLocationSharingPreference(_ preference: LocationSharingPreference) {
        let resolvedPreference = resolvedLocationSharingPreference(from: preference)
        selectedLocationSharingPreference = resolvedPreference
        locationSharingPreferencesStore.selectedPreference = resolvedPreference
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

    private func resolvedLocationSharingPreference(from preference: LocationSharingPreference) -> LocationSharingPreference {
        availableLocationSharingPreferences.first(where: { $0 == preference }) ?? availableLocationSharingPreferences[0]
    }
}
