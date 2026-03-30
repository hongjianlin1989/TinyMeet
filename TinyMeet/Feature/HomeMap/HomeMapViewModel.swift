import Combine
import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class HomeMapViewModel: ObservableObject {
    struct OverlayState {
        let titleKey: LocalizedStringResource
        let messageKey: LocalizedStringResource
        let buttonTitleKey: LocalizedStringResource?
    }

    @Published var isShowingLoginView = false
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var overlayState: OverlayState?
    @Published private(set) var privateEvents: [PrivateEventMapItem]

    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private var hasCenteredOnUser = false

    init(locationManager: LocationManager? = nil) {
        let locationManager = locationManager ?? LocationManager()
        self.locationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus
        self.privateEvents = PrivateEventMapItem.mockItems
        bindLocationManager()
        updateOverlayState(for: authorizationStatus)
    }

    func onAppear() {
        loadPrivateEvents()
        requestLocationAccess()
    }

    func loginTapped() {
        isShowingLoginView = true
    }

    func requestLocationAccess() {
        locationManager.requestLocationAccess()
    }

    private func loadPrivateEvents() {
        privateEvents = PrivateEventMapItem.mockItems
    }

    private func bindLocationManager() {
        locationManager.$authorizationStatus
            .removeDuplicates()
            .sink { [weak self] status in
                self?.handleAuthorizationChange(status)
            }
            .store(in: &cancellables)

        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        updateOverlayState(for: status)

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingIfAuthorized()
        }
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        guard !hasCenteredOnUser else { return }
        hasCenteredOnUser = true

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }

    private func updateOverlayState(for status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            overlayState = OverlayState(
                titleKey: "home.location.finding.title",
                messageKey: "home.location.finding.message",
                buttonTitleKey: "home.location.enable"
            )
        case .denied, .restricted:
            overlayState = OverlayState(
                titleKey: "home.location.disabled.title",
                messageKey: "home.location.disabled.message",
                buttonTitleKey: nil
            )
        case .authorizedAlways, .authorizedWhenInUse:
            overlayState = nil
        @unknown default:
            overlayState = nil
        }
    }
}
