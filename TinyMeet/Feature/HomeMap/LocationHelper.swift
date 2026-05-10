import Combine
import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class LocationHelper: ObservableObject {
    struct OverlayState {
        let titleKey: LocalizedStringResource
        let messageKey: LocalizedStringResource
        let buttonTitleKey: LocalizedStringResource?
    }

    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var overlayState: OverlayState?
    @Published private(set) var locationSharingPromptPlaydate: InterestedPlaydateMapDetail?

    private let locationManager: LocationManager
    private let locationRepository: LocationRepositoryProtocol
    private let locationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol
    private let currentDateProvider: @Sendable () -> Date
    private var cancellables = Set<AnyCancellable>()
    private var hasCenteredOnUser = false
    private var latestLocation: CLLocation?
    private var selectedPlaydate: InterestedPlaydateMapDetail?
    private var selectedAttendees: [InterestedPersonLocation] = []
    private var locationUploadTask: Task<Void, Never>?
    private var lastUploadedLocation: CLLocation?
    private var lastUploadedEventID: UUID?

    private static let minimumUploadDistance: CLLocationDistance = 500
    private static let addingTimeInterval: Double = -33600
    
    init(
        locationManager: LocationManager? = nil,
        locationRepository: LocationRepositoryProtocol? = nil,
        locationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol? = nil,
        currentDateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        let locationManager = locationManager ?? LocationManager()
        self.locationManager = locationManager
        self.locationRepository = locationRepository ?? LocationRepository(shouldUseMockData: false)
        self.locationSharingPreferencesStore = locationSharingPreferencesStore ?? UserDefaultsLocationSharingPreferencesStore.shared
        self.currentDateProvider = currentDateProvider
        self.authorizationStatus = locationManager.authorizationStatus
        bindLocationManager()
        updateOverlayState(for: authorizationStatus)
    }

    deinit {
        locationUploadTask?.cancel()
    }

    func requestLocationAccess() {
        locationManager.requestLocationAccess()
    }

    func resetForSignedOutState() {
        locationUploadTask?.cancel()
        locationUploadTask = nil
        locationManager.stopUpdating()
        selectedPlaydate = nil
        selectedAttendees = []
        locationSharingPromptPlaydate = nil
        latestLocation = nil
        hasCenteredOnUser = false
        lastUploadedLocation = nil
        lastUploadedEventID = nil
        cameraPosition = .automatic
        updateOverlayState(for: authorizationStatus)
    }

    func setContext(
        selectedPlaydate: InterestedPlaydateMapDetail?,
        attendees: [InterestedPersonLocation],
        resetPrompt: Bool = false
    ) {
        let previousSelectedPlaydateID = self.selectedPlaydate?.id
        self.selectedPlaydate = selectedPlaydate
        self.selectedAttendees = attendees

        let didChangeSelectedPlaydate = previousSelectedPlaydateID != selectedPlaydate?.id
        if didChangeSelectedPlaydate {
            resetLocationUploadStateIfNeeded(for: selectedPlaydate?.id)
        }

        if resetPrompt || didChangeSelectedPlaydate {
            locationSharingPromptPlaydate = nil
        }

        evaluateLocationSharingPrompt()
        uploadSelectedLocationIfNeeded()
    }

    func approveLocationSharing() {
        guard let playdate = locationSharingPromptPlaydate else { return }
        rememberLocationSharingDecision(.share, for: playdate)
        locationSharingPromptPlaydate = nil
        requestLocationAccess()
        uploadSelectedLocationIfNeeded()
    }

    func declineLocationSharing() {
        guard let playdate = locationSharingPromptPlaydate else { return }
        rememberLocationSharingDecision(.notNow, for: playdate)
        locationSharingPromptPlaydate = nil
    }

    func dismissLocationSharingPrompt() {
        locationSharingPromptPlaydate = nil
    }

    func recenterOnCurrentContext() {
        guard let selectedPlaydate else { return }

        var coordinates = [selectedPlaydate.coordinate]
        coordinates.append(contentsOf: selectedAttendees.map(\.coordinate))

        if let latestLocation {
            coordinates.append(latestLocation.coordinate)
        }

        cameraPosition = .region(Self.regionFitting(coordinates))
    }
}

private extension LocationHelper {
    func bindLocationManager() {
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

    func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        updateOverlayState(for: status)

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingIfAuthorized()
            uploadSelectedLocationIfNeeded()
        }
    }

    func handleLocationUpdate(_ location: CLLocation) {
        latestLocation = location

        if selectedPlaydate == nil {
            guard hasCenteredOnUser == false else { return }
            hasCenteredOnUser = true
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }

        evaluateLocationSharingPrompt()
        uploadSelectedLocationIfNeeded()
    }

    func evaluateLocationSharingPrompt() {
        cleanupExpiredLocationSharingMemories()

        guard let selectedPlaydate,
              isWithinLocationSharingWindow(for: selectedPlaydate) else {
            locationSharingPromptPlaydate = nil
            return
        }

        switch locationSharingPreferencesStore.selectedPreference {
        case .alwaysShareWhenPlaydateIsAboutToStart:
            locationSharingPromptPlaydate = nil
        case .askEveryTimeForEachEvent:
            guard locationSharingPreferencesStore.eventDecision(
                for: selectedPlaydate.id,
                referenceDate: currentDateProvider()
            ) == nil else {
                locationSharingPromptPlaydate = nil
                return
            }

            locationSharingPromptPlaydate = selectedPlaydate
        }
    }

    func uploadSelectedLocationIfNeeded() {
        guard let selectedPlaydate,
              shouldShareLocation(for: selectedPlaydate),
              isWithinLocationSharingWindow(for: selectedPlaydate),
              let latestLocation,
              shouldShowLocation else {
            return
        }

        guard shouldUploadLocation(latestLocation, for: selectedPlaydate.id) else {
            return
        }

        locationUploadTask?.cancel()
        locationUploadTask = Task { [locationRepository] in
            do {
                try await locationRepository.updateCurrentLocation(
                    latitude: latestLocation.coordinate.latitude,
                    longitude: latestLocation.coordinate.longitude
                )

                await MainActor.run {
                    self.lastUploadedLocation = latestLocation
                    self.lastUploadedEventID = selectedPlaydate.id
                }
            } catch {
                // Ignore upload failures for now; a later location update can retry.
            }
        }
    }

    func shouldShareLocation(for playdate: InterestedPlaydateMapDetail) -> Bool {
        switch locationSharingPreferencesStore.selectedPreference {
        case .alwaysShareWhenPlaydateIsAboutToStart:
            return true
        case .askEveryTimeForEachEvent:
            return locationSharingPreferencesStore.eventDecision(
                for: playdate.id,
                referenceDate: currentDateProvider()
            ) == .share
        }
    }

    func rememberLocationSharingDecision(
        _ decision: LocationSharingEventDecision,
        for playdate: InterestedPlaydateMapDetail
    ) {
        locationSharingPreferencesStore.rememberEventDecision(
            decision,
            for: playdate.id,
            endsAt: playdate.endsAt
        )
    }

    func cleanupExpiredLocationSharingMemories() {
        locationSharingPreferencesStore.cleanupExpiredDecisions(referenceDate: currentDateProvider())
    }

    func isWithinLocationSharingWindow(for playdate: InterestedPlaydateMapDetail) -> Bool {
        guard let scheduledAt = playdate.scheduledAt,
              let endsAt = playdate.endsAt else {
            return false
        }

        let now = currentDateProvider()
        let sharingStart = scheduledAt.addingTimeInterval(
            LocationHelper.addingTimeInterval
        )
        return now >= sharingStart && now < endsAt
    }

    var shouldShowLocation: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    func shouldUploadLocation(_ location: CLLocation, for eventID: UUID) -> Bool {
        guard location.horizontalAccuracy >= 0 else { return false }

        guard lastUploadedEventID == eventID,
              let lastUploadedLocation else {
            return true
        }

        return location.distance(from: lastUploadedLocation) >= Self.minimumUploadDistance
    }

    func resetLocationUploadStateIfNeeded(for eventID: UUID?) {
        if lastUploadedEventID != eventID {
            lastUploadedLocation = nil
            lastUploadedEventID = nil
        }
    }

    static func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? first.latitude
        let maxLatitude = latitudes.max() ?? first.latitude
        let minLongitude = longitudes.min() ?? first.longitude
        let maxLongitude = longitudes.max() ?? first.longitude
        let latitudeDelta = max((maxLatitude - minLatitude) * 1.6, 0.01)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.6, 0.01)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    func updateOverlayState(for status: CLAuthorizationStatus) {
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
