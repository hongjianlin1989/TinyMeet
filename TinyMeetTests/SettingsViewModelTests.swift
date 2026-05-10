import Foundation
import Testing
@testable import TinyMeet

struct SettingsViewModelTests {
    final class MockLocationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol {
        var selectedPreference: LocationSharingPreference

        init(selectedPreference: LocationSharingPreference = .askEveryTimeForEachEvent) {
            self.selectedPreference = selectedPreference
        }

        func eventDecision(for eventID: UUID, referenceDate: Date) -> LocationSharingEventDecision? {
            nil
        }

        func rememberEventDecision(_ decision: LocationSharingEventDecision, for eventID: UUID, endsAt: Date?) {}

        func clearEventDecision(for eventID: UUID) {}

        func cleanupExpiredDecisions(referenceDate: Date) {}
    }

    @MainActor
    @Test func initUsesPersistedLocationSharingPreference() {
        let store = MockLocationSharingPreferencesStore(selectedPreference: .alwaysShareWhenPlaydateIsAboutToStart)

        let viewModel = SettingsViewModel(locationSharingPreferencesStore: store)

        #expect(viewModel.selectedLocationSharingPreference == .alwaysShareWhenPlaydateIsAboutToStart)
        #expect(viewModel.selectedLocationSharingOption == .alwaysShareWhenPlaydateIsAboutToStart)
    }

    @MainActor
    @Test func updateSelectedLocationSharingPreferencePersistsSelection() {
        let store = MockLocationSharingPreferencesStore()
        let viewModel = SettingsViewModel(locationSharingPreferencesStore: store)

        viewModel.updateSelectedLocationSharingPreference(.alwaysShareWhenPlaydateIsAboutToStart)

        #expect(viewModel.selectedLocationSharingPreference == .alwaysShareWhenPlaydateIsAboutToStart)
        #expect(store.selectedPreference == .alwaysShareWhenPlaydateIsAboutToStart)
    }

    @MainActor
    @Test func refreshSelectedLocationSharingPreferenceReloadsExternalChanges() {
        let store = MockLocationSharingPreferencesStore(selectedPreference: .askEveryTimeForEachEvent)
        let viewModel = SettingsViewModel(locationSharingPreferencesStore: store)

        store.selectedPreference = .alwaysShareWhenPlaydateIsAboutToStart
        viewModel.refreshSelectedLocationSharingPreference()

        #expect(viewModel.selectedLocationSharingPreference == .alwaysShareWhenPlaydateIsAboutToStart)
        #expect(viewModel.selectedLocationSharingOption == .alwaysShareWhenPlaydateIsAboutToStart)
    }

    @MainActor
    @Test func unavailablePersistedPreferenceFallsBackToAvailableOption() {
        let store = MockLocationSharingPreferencesStore(selectedPreference: .alwaysShareWhenPlaydateIsAboutToStart)

        let viewModel = SettingsViewModel(
            locationSharingPreferencesStore: store,
            availableLocationSharingPreferences: [.askEveryTimeForEachEvent]
        )

        #expect(viewModel.selectedLocationSharingPreference == .askEveryTimeForEachEvent)
        #expect(viewModel.selectedLocationSharingOption == .askEveryTimeForEachEvent)

        store.selectedPreference = .alwaysShareWhenPlaydateIsAboutToStart
        viewModel.refreshSelectedLocationSharingPreference()

        #expect(viewModel.selectedLocationSharingPreference == .askEveryTimeForEachEvent)
    }
}
