import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    var shouldShowLocation: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var shouldShowDeniedMessage: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestLocationAccess() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func startUpdatingIfAuthorized() {
        guard shouldShowLocation else { return }
        manager.startUpdatingLocation()
        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if shouldShowLocation {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latestLocation = locations.last {
            location = latestLocation
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
    }
}
