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

    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var overlayState: OverlayState?
    @Published private(set) var interestedPlaydates: [InterestedPlaydateMapDetail]
    @Published private(set) var selectedPlaydateID: UUID?
    @Published private(set) var isLoadingInterestedPlaydates: Bool = false
    @Published private(set) var interestedPlaydatesErrorMessage: String?

    private let locationManager: LocationManager
    private let interestedEventsRepository: InterestedEventsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var hasCenteredOnUser = false
    private var latestLocation: CLLocation?
    private var interestedPlaydatesFetchTask: Task<Void, Never>?

    init(
        locationManager: LocationManager? = nil,
        interestedEventsRepository: InterestedEventsRepositoryProtocol? = nil
    ) {
        let locationManager = locationManager ?? LocationManager()
        self.locationManager = locationManager
        let isRunningPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        self.interestedEventsRepository = interestedEventsRepository ?? InterestedEventsRepository()
        self.authorizationStatus = locationManager.authorizationStatus
        self.interestedPlaydates = []
        bindLocationManager()
        updateOverlayState(for: authorizationStatus)
    }

    deinit {
        interestedPlaydatesFetchTask?.cancel()
    }

    func onAppear() {
        refreshInterestedPlaydates()
        requestLocationAccess()
    }

    func requestLocationAccess() {
        locationManager.requestLocationAccess()
    }

    func refreshInterestedPlaydates() {
        interestedPlaydatesFetchTask?.cancel()

        interestedPlaydatesFetchTask = Task { [weak self] in
            await self?.loadInterestedPlaydates()
        }
    }

    var selectedPlaydate: InterestedPlaydateMapDetail? {
        interestedPlaydates.first(where: { $0.id == selectedPlaydateID })
    }

    var selectedPlaydateEvent: PrivateEventMapItem? {
        selectedPlaydate?.event
    }

    var selectedInterestedPeople: [InterestedPersonLocation] {
        selectedPlaydate?.interestedPeople ?? []
    }

    func selectPlaydate(_ id: UUID) {
        guard selectedPlaydateID != id else { return }
        selectedPlaydateID = id
        updateCameraForSelectedPlaydate()
    }

    func loadInterestedPlaydates() async {
        isLoadingInterestedPlaydates = true
        interestedPlaydatesErrorMessage = nil

        do {
            let playdates = try await interestedEventsRepository.fetchInterestedPrivatePlaydates()
            guard Task.isCancelled == false else { return }

            interestedPlaydates = playdates.sorted(by: Self.playdateSortOrder)

            if let selectedPlaydateID,
               interestedPlaydates.contains(where: { $0.id == selectedPlaydateID }) {
                self.selectedPlaydateID = selectedPlaydateID
            } else {
                self.selectedPlaydateID = interestedPlaydates.first?.id
            }

            updateCameraForSelectedPlaydate()
        } catch {
            guard Task.isCancelled == false else { return }
            interestedPlaydatesErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            interestedPlaydates = []
            selectedPlaydateID = nil
        }

        isLoadingInterestedPlaydates = false
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
        latestLocation = location

        if selectedPlaydate == nil {
            guard !hasCenteredOnUser else { return }
            hasCenteredOnUser = true
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        } else {
            updateCameraForSelectedPlaydate()
        }
    }

    private func updateCameraForSelectedPlaydate() {
        guard let selectedPlaydate else { return }

        var coordinates = [selectedPlaydate.coordinate]
        coordinates.append(contentsOf: selectedPlaydate.interestedPeople.map(\.coordinate))

        if let latestLocation {
            coordinates.append(latestLocation.coordinate)
        }

        cameraPosition = .region(Self.regionFitting(coordinates))
    }

    private static func playdateSortOrder(_ lhs: InterestedPlaydateMapDetail, _ rhs: InterestedPlaydateMapDetail) -> Bool {
        switch (lhs.scheduledAt, rhs.scheduledAt) {
        case let (lhsDate?, rhsDate?):
            return lhsDate < rhsDate
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private static func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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
