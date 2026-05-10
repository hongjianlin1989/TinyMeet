import Foundation
import Testing
@testable import TinyMeet

struct LocationSharingPreferencesStoreTests {
    @Test func selectedPreferencePersistsAcrossStoreInstances() {
        let suiteName = "LocationSharingPreferencesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsLocationSharingPreferencesStore(userDefaults: defaults)
        store.selectedPreference = .alwaysShareWhenPlaydateIsAboutToStart

        let reloadedStore = UserDefaultsLocationSharingPreferencesStore(userDefaults: defaults)
        #expect(reloadedStore.selectedPreference == .alwaysShareWhenPlaydateIsAboutToStart)
    }

    @Test func eventDecisionsExpireAfterEventEnds() {
        let suiteName = "LocationSharingPreferencesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsLocationSharingPreferencesStore(userDefaults: defaults)
        let eventID = UUID()
        let futureEndDate = Date().addingTimeInterval(3600)
        let afterEndDate = futureEndDate.addingTimeInterval(60)

        store.rememberEventDecision(.share, for: eventID, endsAt: futureEndDate)
        #expect(store.eventDecision(for: eventID, referenceDate: futureEndDate.addingTimeInterval(-60)) == .share)

        store.cleanupExpiredDecisions(referenceDate: afterEndDate)
        #expect(store.eventDecision(for: eventID, referenceDate: afterEndDate) == nil)
    }
}
