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
    @Published private(set) var selectedAttendees: [InterestedPersonLocation]
    @Published private(set) var locationSharingPromptPlaydate: InterestedPlaydateMapDetail?
    @Published private(set) var isLoadingInterestedPlaydates: Bool = false
    @Published private(set) var interestedPlaydatesErrorMessage: String?

    private let locationManager: LocationManager
    private let interestedEventsRepository: InterestedEventsRepositoryProtocol
    private let locationRepository: LocationRepositoryProtocol
    private let currentDateProvider: @Sendable () -> Date
    private var cancellables = Set<AnyCancellable>()
    private var hasCenteredOnUser = false
    private var latestLocation: CLLocation?
    private var interestedPlaydatesFetchTask: Task<Void, Never>?
    private var attendeesFetchTask: Task<Void, Never>?
    private var locationUploadTask: Task<Void, Never>?
    private var approvedLocationSharingEventIDs = Set<UUID>()
    private var declinedLocationSharingEventIDs = Set<UUID>()
    private var lastUploadedLocation: CLLocation?
    private var lastUploadedEventID: UUID?

    private static let minimumUploadDistance: CLLocationDistance = 500

    init(
        locationManager: LocationManager? = nil,
        interestedEventsRepository: InterestedEventsRepositoryProtocol? = nil,
        locationRepository: LocationRepositoryProtocol? = nil,
        currentDateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        let locationManager = locationManager ?? LocationManager()
        self.locationManager = locationManager
        self.interestedEventsRepository = interestedEventsRepository ?? InterestedEventsRepository()
        self.locationRepository = locationRepository ?? LocationRepository(shouldUseMockData: false)
        self.currentDateProvider = currentDateProvider
        self.authorizationStatus = locationManager.authorizationStatus
        self.interestedPlaydates = []
        self.selectedAttendees = []
        self.locationSharingPromptPlaydate = nil
        bindLocationManager()
        updateOverlayState(for: authorizationStatus)
    }

    deinit {
        interestedPlaydatesFetchTask?.cancel()
        attendeesFetchTask?.cancel()
        locationUploadTask?.cancel()
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
        selectedAttendees
    }

    func selectPlaydate(_ id: UUID) {
        guard selectedPlaydateID != id else { return }
        selectedPlaydateID = id
        clearSelectedAttendees()
        locationSharingPromptPlaydate = nil
        resetLocationUploadStateIfNeeded(for: id)
        loadAttendees(for: id)
        evaluateLocationSharingPrompt()
        uploadSelectedLocationIfNeeded()
        recenterOnSelectedPlaydate()
    }

    func approveLocationSharing() {
        guard let playdate = locationSharingPromptPlaydate else { return }
        approvedLocationSharingEventIDs.insert(playdate.id)
        declinedLocationSharingEventIDs.remove(playdate.id)
        locationSharingPromptPlaydate = nil
        requestLocationAccess()
        uploadSelectedLocationIfNeeded()
    }

    func declineLocationSharing() {
        guard let playdate = locationSharingPromptPlaydate else { return }
        declinedLocationSharingEventIDs.insert(playdate.id)
        approvedLocationSharingEventIDs.remove(playdate.id)
        locationSharingPromptPlaydate = nil
    }

    func dismissLocationSharingPrompt() {
        locationSharingPromptPlaydate = nil
    }

    func loadInterestedPlaydates() async {
        isLoadingInterestedPlaydates = true
        interestedPlaydatesErrorMessage = nil

        do {
            let previousSelectedPlaydateID = selectedPlaydateID
            let playdates = try await interestedEventsRepository.fetchInterestedPrivatePlaydates()
            guard Task.isCancelled == false else { return }

            interestedPlaydates = playdates.sorted(by: Self.playdateSortOrder)

            if let selectedPlaydateID,
               interestedPlaydates.contains(where: { $0.id == selectedPlaydateID }) {
                self.selectedPlaydateID = selectedPlaydateID
            } else {
                self.selectedPlaydateID = interestedPlaydates.first?.id
            }

            let didChangeSelectedPlaydate = self.selectedPlaydateID != previousSelectedPlaydateID

            clearSelectedAttendees()

            if let selectedPlaydateID = self.selectedPlaydateID {
                await fetchAttendees(for: selectedPlaydateID)
            }

            evaluateLocationSharingPrompt()
            uploadSelectedLocationIfNeeded()

            if didChangeSelectedPlaydate {
                recenterOnSelectedPlaydate()
            }
        } catch {
            guard Task.isCancelled == false else { return }
            interestedPlaydatesErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            interestedPlaydates = []
            selectedPlaydateID = nil
            clearSelectedAttendees()
        }

        isLoadingInterestedPlaydates = false
    }
}

private extension HomeMapViewModel {
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
            uploadSelectedLocationIfNeeded()
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
        }

        evaluateLocationSharingPrompt()
        uploadSelectedLocationIfNeeded()
    }

    private func recenterOnSelectedPlaydate() {
        guard let selectedPlaydate else { return }

        var coordinates = [selectedPlaydate.coordinate]
        coordinates.append(contentsOf: selectedAttendees.map(\.coordinate))

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

    private func loadAttendees(for playdateID: UUID) {
        attendeesFetchTask?.cancel()

        attendeesFetchTask = Task { [weak self] in
            await self?.fetchAttendees(for: playdateID)
        }
    }

    private func fetchAttendees(for playdateID: UUID) async {
        do {
            let attendees = try await interestedEventsRepository.fetchPrivateEventAttendees(eventID: playdateID)
            guard Task.isCancelled == false else { return }
            guard selectedPlaydateID == playdateID else { return }

            selectedAttendees = attendees
        } catch {
            guard Task.isCancelled == false else { return }
            guard selectedPlaydateID == playdateID else { return }

            selectedAttendees = []
        }
    }

    private func clearSelectedAttendees() {
        attendeesFetchTask?.cancel()
        selectedAttendees = []
    }

    private func evaluateLocationSharingPrompt() {
        guard let selectedPlaydate,
              isWithinLocationSharingWindow(for: selectedPlaydate) else {
            locationSharingPromptPlaydate = nil
            return
        }

        guard approvedLocationSharingEventIDs.contains(selectedPlaydate.id) == false,
              declinedLocationSharingEventIDs.contains(selectedPlaydate.id) == false else {
            return
        }

        locationSharingPromptPlaydate = selectedPlaydate
    }

    private func uploadSelectedLocationIfNeeded() {
        guard let selectedPlaydate,
              approvedLocationSharingEventIDs.contains(selectedPlaydate.id),
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

    private func isWithinLocationSharingWindow(for playdate: InterestedPlaydateMapDetail) -> Bool {
        guard let scheduledAt = playdate.scheduledAt,
              let endsAt = playdate.endsAt else {
            return false
        }

        let now = currentDateProvider()
        let sharingStart = scheduledAt.addingTimeInterval(-3600)
        return now >= sharingStart && now < endsAt
    }

    private var shouldShowLocation: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    private func shouldUploadLocation(_ location: CLLocation, for eventID: UUID) -> Bool {
        guard location.horizontalAccuracy >= 0 else { return false }

        guard lastUploadedEventID == eventID,
              let lastUploadedLocation else {
            return true
        }

        return location.distance(from: lastUploadedLocation) >= Self.minimumUploadDistance
    }

    private func resetLocationUploadStateIfNeeded(for eventID: UUID) {
        if lastUploadedEventID != eventID {
            lastUploadedLocation = nil
            lastUploadedEventID = nil
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
