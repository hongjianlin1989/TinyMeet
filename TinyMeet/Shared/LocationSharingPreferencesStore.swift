import Foundation

enum LocationSharingPreference: String, CaseIterable, Identifiable, Sendable {
    case alwaysShareWhenPlaydateIsAboutToStart
    case askEveryTimeForEachEvent

    var id: String { rawValue }

    var titleLocalizationKey: String {
        switch self {
        case .alwaysShareWhenPlaydateIsAboutToStart:
            return "settings.locationSharing.alwaysShare.title"
        case .askEveryTimeForEachEvent:
            return "settings.locationSharing.askEveryTime.title"
        }
    }

    var detailLocalizationKey: String {
        switch self {
        case .alwaysShareWhenPlaydateIsAboutToStart:
            return "settings.locationSharing.alwaysShare.detail"
        case .askEveryTimeForEachEvent:
            return "settings.locationSharing.askEveryTime.detail"
        }
    }
}

enum LocationSharingEventDecision: String, Codable, Sendable {
    case share
    case notNow
}

protocol LocationSharingPreferencesStoreProtocol {
    var selectedPreference: LocationSharingPreference { get set }

    func eventDecision(for eventID: UUID, referenceDate: Date) -> LocationSharingEventDecision?
    func rememberEventDecision(_ decision: LocationSharingEventDecision, for eventID: UUID, endsAt: Date?)
    func clearEventDecision(for eventID: UUID)
    func cleanupExpiredDecisions(referenceDate: Date)
}

final class UserDefaultsLocationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol {
    static let shared = UserDefaultsLocationSharingPreferencesStore()

    private enum Keys {
        static let selectedPreference = "locationSharing.selectedPreference"
        static let eventDecisions = "locationSharing.eventDecisions"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var selectedPreference: LocationSharingPreference {
        get {
            guard let rawValue = userDefaults.string(forKey: Keys.selectedPreference),
                  let preference = LocationSharingPreference(rawValue: rawValue) else {
                return .askEveryTimeForEachEvent
            }

            return preference
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.selectedPreference)
        }
    }

    func eventDecision(for eventID: UUID, referenceDate: Date) -> LocationSharingEventDecision? {
        cleanupExpiredDecisions(referenceDate: referenceDate)
        return loadStoredDecisions()[eventID.uuidString]?.decision
    }

    func rememberEventDecision(_ decision: LocationSharingEventDecision, for eventID: UUID, endsAt: Date?) {
        guard let endsAt, endsAt > Date() else {
            clearEventDecision(for: eventID)
            return
        }

        var storedDecisions = loadStoredDecisions()
        storedDecisions[eventID.uuidString] = StoredDecision(decision: decision, endsAt: endsAt)
        saveStoredDecisions(storedDecisions)
    }

    func clearEventDecision(for eventID: UUID) {
        var storedDecisions = loadStoredDecisions()
        storedDecisions.removeValue(forKey: eventID.uuidString)
        saveStoredDecisions(storedDecisions)
    }

    func cleanupExpiredDecisions(referenceDate: Date) {
        let storedDecisions = loadStoredDecisions()
        let filteredDecisions = storedDecisions.filter { _, storedDecision in
            storedDecision.endsAt > referenceDate
        }

        guard filteredDecisions.count != storedDecisions.count else { return }
        saveStoredDecisions(filteredDecisions)
    }

    private func loadStoredDecisions() -> [String: StoredDecision] {
        guard let data = userDefaults.data(forKey: Keys.eventDecisions),
              let storedDecisions = try? decoder.decode([String: StoredDecision].self, from: data) else {
            return [:]
        }

        return storedDecisions
    }

    private func saveStoredDecisions(_ storedDecisions: [String: StoredDecision]) {
        guard let data = try? encoder.encode(storedDecisions) else { return }
        userDefaults.set(data, forKey: Keys.eventDecisions)
    }
}

private struct StoredDecision: Codable, Sendable {
    let decision: LocationSharingEventDecision
    let endsAt: Date
}
