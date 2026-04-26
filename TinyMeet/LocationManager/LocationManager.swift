import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?

    private let manager: CLLocationManager
    private let locationRepository: LocationRepositoryProtocol
    private var lastUploadedLocation: CLLocation?
    private var locationUploadTask: Task<Void, Never>?

    private static let minimumUploadDistance: CLLocationDistance = 500

    init(locationRepository: LocationRepositoryProtocol = LocationRepository()) {
        let manager = CLLocationManager()
        self.manager = manager
        self.locationRepository = locationRepository
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

    private func startLocationServices() {
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
        manager.requestLocation()
    }

    private func uploadLocationIfNeeded(_ newLocation: CLLocation) {
        guard shouldUploadLocation(newLocation) else { return }

        locationUploadTask?.cancel()
        locationUploadTask = Task { [locationRepository] in
            do {
                try await locationRepository.updateCurrentLocation(
                    latitude: newLocation.coordinate.latitude,
                    longitude: newLocation.coordinate.longitude
                )

                await MainActor.run {
                    self.lastUploadedLocation = newLocation
                }
            } catch {
                // Ignore upload failures for now; a future significant location change will retry.
            }
        }
    }

    private func shouldUploadLocation(_ newLocation: CLLocation) -> Bool {
        guard newLocation.horizontalAccuracy >= 0 else { return false }

        guard let lastUploadedLocation else {
            return true
        }

        return newLocation.distance(from: lastUploadedLocation) >= Self.minimumUploadDistance
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
            self?.uploadLocationIfNeeded(latestLocation)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
    }
}
