import CoreLocation
import Foundation

@MainActor
protocol HomePostalCodeProviding {
    func currentPostalCode() async -> String?
}

@MainActor
final class HomePostalCodeProvider: HomePostalCodeProviding {
    private let locationManager: LocationManager
    private let geocoder: CLGeocoder
    private let userDefaults: UserDefaults

    init(
        locationManager: LocationManager? = nil,
        geocoder: CLGeocoder? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.locationManager = locationManager ?? LocationManager()
        self.geocoder = geocoder ?? CLGeocoder()
        self.userDefaults = userDefaults
    }

    func currentPostalCode() async -> String? {
        if let cachedPostalCode = cachedPostalCode {
            return cachedPostalCode
        }

        guard let location = await currentLocation() else {
            return nil
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let postalCode = placemarks.first?.postalCode?.trimmingCharacters(in: .whitespacesAndNewlines)

            if let postalCode, postalCode.isEmpty == false {
                userDefaults.set(postalCode, forKey: Self.cachedPostalCodeKey)
                return postalCode
            }
        } catch {
            return cachedPostalCode
        }

        return nil
    }
}

private extension HomePostalCodeProvider {
    static let cachedPostalCodeKey = "home.events.cachedPostalCode"

    var cachedPostalCode: String? {
        guard let postalCode = userDefaults.string(forKey: Self.cachedPostalCodeKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              postalCode.isEmpty == false else {
            return nil
        }

        return postalCode
    }

    func currentLocation() async -> CLLocation? {
        if let location = locationManager.location {
            return location
        }

        guard locationManager.shouldShowLocation else {
            return nil
        }

        locationManager.startUpdatingIfAuthorized()

        for _ in 0..<10 {
            if let location = locationManager.location {
                return location
            }

            try? await Task.sleep(for: .milliseconds(200))
        }

        return locationManager.location
    }
}
