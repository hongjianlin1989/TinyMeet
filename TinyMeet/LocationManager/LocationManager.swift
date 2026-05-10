import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?

    private let manager: CLLocationManager
    private var isMonitoringSignificantLocationChanges = false

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
            startLocationServices()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func startUpdatingIfAuthorized() {
        guard shouldShowLocation else { return }
        startLocationServices()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()

        if isMonitoringSignificantLocationChanges {
            manager.stopMonitoringSignificantLocationChanges()
            isMonitoringSignificantLocationChanges = false
        }
    }

    private func startLocationServices() {
        manager.stopUpdatingLocation()

        if isMonitoringSignificantLocationChanges == false {
            manager.startMonitoringSignificantLocationChanges()
            isMonitoringSignificantLocationChanges = true
        }

        manager.requestLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            authorizationStatus = manager.authorizationStatus

            if shouldShowLocation {
                startLocationServices()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        Task { @MainActor [weak self] in
            self?.location = latestLocation
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
    }
}
