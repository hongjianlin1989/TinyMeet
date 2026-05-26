import Combine
import MapKit
import SwiftUI

@MainActor
final class HomeMapViewModel: ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic {
        didSet {
            guard isSyncingCameraPositionFromHelper == false else { return }
            locationHelper.cameraPosition = cameraPosition
        }
    }

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var overlayState: LocationHelper.OverlayState?
    @Published private(set) var interestedPlaydates: [InterestedPlaydateMapDetail]
    @Published private(set) var selectedPlaydateID: UUID?
    @Published private(set) var selectedAttendees: [InterestedPersonLocation]
    @Published private(set) var locationSharingPromptPlaydate: InterestedPlaydateMapDetail?
    @Published private(set) var isLoadingInterestedPlaydates = false
    @Published private(set) var interestedPlaydatesErrorMessage: String?

    private let interestedEventsRepository: InterestedEventsRepositoryProtocol
    private let locationHelper: LocationHelper
    private let attendeeRefreshInterval: Duration
    private var isAuthenticated: Bool
    private var isMapVisible = false
    private var cancellables = Set<AnyCancellable>()
    private var interestedPlaydatesFetchTask: Task<Void, Never>?
    private var attendeesFetchTask: Task<Void, Never>?
    private var isSyncingCameraPositionFromHelper = false

    init(
        locationManager: LocationManager? = nil,
        interestedEventsRepository: InterestedEventsRepositoryProtocol? = nil,
        locationRepository: LocationRepositoryProtocol? = nil,
        locationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol? = nil,
        currentDateProvider: @escaping @Sendable () -> Date = Date.init,
        locationHelper: LocationHelper? = nil,
        attendeeRefreshInterval: Duration = .seconds(30),
        isAuthenticated: Bool = false
    ) {
        let resolvedLocationHelper = locationHelper ?? LocationHelper(
            locationManager: locationManager,
            locationRepository: locationRepository,
            locationSharingPreferencesStore: locationSharingPreferencesStore,
            currentDateProvider: currentDateProvider
        )

        self.interestedEventsRepository = interestedEventsRepository ?? InterestedEventsRepository()
        self.locationHelper = resolvedLocationHelper
        self.attendeeRefreshInterval = attendeeRefreshInterval
        self.isAuthenticated = isAuthenticated
        self.cameraPosition = resolvedLocationHelper.cameraPosition
        self.authorizationStatus = resolvedLocationHelper.authorizationStatus
        self.overlayState = resolvedLocationHelper.overlayState
        self.interestedPlaydates = []
        self.selectedAttendees = []
        self.locationSharingPromptPlaydate = resolvedLocationHelper.locationSharingPromptPlaydate
        bindLocationHelper()
    }

    deinit {
        interestedPlaydatesFetchTask?.cancel()
        attendeesFetchTask?.cancel()
    }

    func onAppear(isLoggedIn: Bool) {
        setMapVisibility(true, isLoggedIn: isLoggedIn)
    }

    func onDisappear() {
        setMapVisibility(false, isLoggedIn: isAuthenticated)
    }

    func authenticationStateChanged(isLoggedIn: Bool) {
        setAuthenticationState(isLoggedIn, shouldRefreshWhenAuthenticated: isMapVisible)
    }

    func setMapVisibility(_ isVisible: Bool, isLoggedIn: Bool) {
        let wasVisible = isMapVisible
        isMapVisible = isVisible

        setAuthenticationState(
            isLoggedIn,
            shouldRefreshWhenAuthenticated: isVisible && (wasVisible == false || interestedPlaydates.isEmpty)
        )

        guard isVisible, isAuthenticated else {
            pauseMapActivity()
            return
        }

        requestLocationAccess()

        if wasVisible == false, interestedPlaydates.isEmpty == false {
            resumeAttendeeRefreshIfNeeded(fetchImmediately: true)
        }
    }

    func requestLocationAccess() {
        guard isAuthenticated else { return }
        locationHelper.requestLocationAccess()
    }

    func refreshInterestedPlaydates() {
        guard isAuthenticated else {
            resetSignedOutState()
            return
        }

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
        guard isAuthenticated else { return }
        guard selectedPlaydateID != id else { return }
        selectedPlaydateID = id
        clearSelectedAttendees(syncLocationContext: false)
        syncLocationContext(resetPrompt: true)
        loadAttendees(for: id)
        locationHelper.recenterOnCurrentContext()
    }

    func approveLocationSharing() {
        guard isAuthenticated else { return }
        locationHelper.approveLocationSharing()
    }

    func declineLocationSharing() {
        guard isAuthenticated else { return }
        locationHelper.declineLocationSharing()
    }

    func dismissLocationSharingPrompt() {
        locationHelper.dismissLocationSharingPrompt()
    }

    func loadInterestedPlaydates() async {
        guard isAuthenticated else {
            resetSignedOutState()
            return
        }

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
            clearSelectedAttendees(syncLocationContext: false)

            if let selectedPlaydateID = self.selectedPlaydateID {
                await fetchAttendees(for: selectedPlaydateID)

                if isMapVisible {
                    startAttendeeRefreshLoop(for: selectedPlaydateID)
                }
            } else {
                syncLocationContext(resetPrompt: didChangeSelectedPlaydate)
            }

            if didChangeSelectedPlaydate {
                locationHelper.recenterOnCurrentContext()
            }
        } catch {
            guard Task.isCancelled == false else { return }
            interestedPlaydatesErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            interestedPlaydates = []
            selectedPlaydateID = nil
            clearSelectedAttendees(syncLocationContext: false)
            syncLocationContext(resetPrompt: true)
        }

        isLoadingInterestedPlaydates = false
    }
}

private extension HomeMapViewModel {
    func bindLocationHelper() {
        locationHelper.$cameraPosition
            .sink { [weak self] cameraPosition in
                guard let self else { return }
                self.isSyncingCameraPositionFromHelper = true
                self.cameraPosition = cameraPosition
                self.isSyncingCameraPositionFromHelper = false
            }
            .store(in: &cancellables)

        locationHelper.$authorizationStatus
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)

        locationHelper.$overlayState
            .sink { [weak self] overlayState in
                self?.overlayState = overlayState
            }
            .store(in: &cancellables)

        locationHelper.$locationSharingPromptPlaydate
            .sink { [weak self] playdate in
                self?.locationSharingPromptPlaydate = playdate
            }
            .store(in: &cancellables)
    }

    func clearSelectedAttendees(syncLocationContext: Bool = true) {
        attendeesFetchTask?.cancel()
        selectedAttendees = []

        if syncLocationContext {
            self.syncLocationContext()
        }
    }

    func loadAttendees(for playdateID: UUID) {
        guard isMapVisible else { return }
        attendeesFetchTask?.cancel()
        attendeesFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchAttendees(for: playdateID)
            await self.pollAttendees(for: playdateID)
        }
    }

    func startAttendeeRefreshLoop(for playdateID: UUID) {
        guard isMapVisible else { return }
        attendeesFetchTask?.cancel()
        attendeesFetchTask = Task { [weak self] in
            await self?.pollAttendees(for: playdateID)
        }
    }

    func resumeAttendeeRefreshIfNeeded(fetchImmediately: Bool) {
        guard isMapVisible, isAuthenticated, let selectedPlaydateID else { return }

        attendeesFetchTask?.cancel()
        attendeesFetchTask = Task { [weak self] in
            guard let self else { return }

            if fetchImmediately {
                await self.fetchAttendees(for: selectedPlaydateID)
            }

            await self.pollAttendees(for: selectedPlaydateID)
        }
    }

    func fetchAttendees(for playdateID: UUID) async {
        guard isAuthenticated else { return }

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

        syncLocationContext()
    }

    func pollAttendees(for playdateID: UUID) async {
        while Task.isCancelled == false {
            do {
                try await Task.sleep(for: attendeeRefreshInterval)
            } catch {
                break
            }

            guard Task.isCancelled == false, isAuthenticated, isMapVisible, selectedPlaydateID == playdateID else { break }
            await fetchAttendees(for: playdateID)
        }
    }

    func setAuthenticationState(_ isLoggedIn: Bool, shouldRefreshWhenAuthenticated: Bool) {
        let didChangeAuthenticationState = isAuthenticated != isLoggedIn
        isAuthenticated = isLoggedIn

        guard didChangeAuthenticationState || shouldRefreshWhenAuthenticated else { return }

        if isLoggedIn {
            guard isMapVisible else { return }
            refreshInterestedPlaydates()
        } else {
            resetSignedOutState()
        }
    }

    func pauseMapActivity() {
        interestedPlaydatesFetchTask?.cancel()
        attendeesFetchTask?.cancel()
    }

    func resetSignedOutState() {
        interestedPlaydatesFetchTask?.cancel()
        attendeesFetchTask?.cancel()
        isLoadingInterestedPlaydates = false
        interestedPlaydatesErrorMessage = nil
        interestedPlaydates = []
        selectedPlaydateID = nil
        selectedAttendees = []
        locationHelper.resetForSignedOutState()
    }

    func syncLocationContext(resetPrompt: Bool = false) {
        locationHelper.setContext(
            selectedPlaydate: selectedPlaydate,
            attendees: selectedAttendees,
            resetPrompt: resetPrompt
        )
    }

    static func playdateSortOrder(_ lhs: InterestedPlaydateMapDetail, _ rhs: InterestedPlaydateMapDetail) -> Bool {
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
}
