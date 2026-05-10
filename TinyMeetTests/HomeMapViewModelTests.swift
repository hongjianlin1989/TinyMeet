import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct HomeMapViewModelTests {
    struct MockInterestedEventsRepository: InterestedEventsRepositoryProtocol {
        let playdates: [InterestedPlaydateMapDetail]
        let attendeesByEventID: [UUID: [InterestedPersonLocation]]
        let playdateFetchSpy: PlaydateFetchSpy?
        let attendeeFetchSpy: AttendeeFetchSpy?

        func fetchInterestedEvents() async throws -> [InterestedEventRow] {
            []
        }

        func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
            if let playdateFetchSpy {
                await playdateFetchSpy.recordFetch()
            }

            return playdates
        }

        func fetchPrivateEventAttendees(eventID: UUID) async throws -> [InterestedPersonLocation] {
            if let attendeeFetchSpy {
                return await attendeeFetchSpy.fetchAttendees(for: eventID)
            }

            return attendeesByEventID[eventID] ?? []
        }

        func setInterested(_ isInterested: Bool, event: NearbyEvent) async throws {}
    }

    actor AttendeeFetchSpy {
        private let attendeesByEventID: [UUID: [InterestedPersonLocation]]
        private var callCounts: [UUID: Int] = [:]

        init(attendeesByEventID: [UUID: [InterestedPersonLocation]]) {
            self.attendeesByEventID = attendeesByEventID
        }

        func fetchAttendees(for eventID: UUID) -> [InterestedPersonLocation] {
            callCounts[eventID, default: 0] += 1
            return attendeesByEventID[eventID] ?? []
        }

        func callCount(for eventID: UUID) -> Int {
            callCounts[eventID, default: 0]
        }
    }

    actor PlaydateFetchSpy {
        private var callCount = 0

        func recordFetch() {
            callCount += 1
        }

        func fetchCount() -> Int {
            callCount
        }
    }

    struct MockLocationRepository: LocationRepositoryProtocol {
        func updateCurrentLocation(latitude: Double, longitude: Double) async throws {}
    }

    final class MockLocationSharingPreferencesStore: LocationSharingPreferencesStoreProtocol {
        var selectedPreference: LocationSharingPreference
        private var storedDecisions: [UUID: StoredDecision] = [:]

        init(selectedPreference: LocationSharingPreference = .askEveryTimeForEachEvent) {
            self.selectedPreference = selectedPreference
        }

        func eventDecision(for eventID: UUID, referenceDate: Date) -> LocationSharingEventDecision? {
            cleanupExpiredDecisions(referenceDate: referenceDate)
            return storedDecisions[eventID]?.decision
        }

        func rememberEventDecision(_ decision: LocationSharingEventDecision, for eventID: UUID, endsAt: Date?) {
            guard let endsAt else { return }
            storedDecisions[eventID] = StoredDecision(decision: decision, endsAt: endsAt)
        }

        func clearEventDecision(for eventID: UUID) {
            storedDecisions.removeValue(forKey: eventID)
        }

        func cleanupExpiredDecisions(referenceDate: Date) {
            storedDecisions = storedDecisions.filter { _, record in
                record.endsAt > referenceDate
            }
        }
    }

    struct StoredDecision {
        let decision: LocationSharingEventDecision
        let endsAt: Date
    }

    @MainActor
    @Test func loadInterestedPlaydatesDefaultsToNearestScheduledPlaydate() async throws {
        let todayPlaydate = makePlaydate(
            title: "Today Playdate",
            subtitle: "Today · 4:30 PM",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-04-26T16:30:00-07:00",
            endsAt: "2026-04-26T18:30:00-07:00",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let futurePlaydate = makePlaydate(
            title: "Future Playdate",
            subtitle: "Saturday · 11:15 AM",
            latitude: 37.3349,
            longitude: -122.0090,
            scheduledAt: "2026-05-02T11:15:00-07:00",
            endsAt: "2026-05-02T13:15:00-07:00",
            tintName: "orange",
            symbolName: "basket.fill"
        )
        let todayAttendees = [makeAttendee(id: UUID().uuidString, name: "Amy Chen", latitude: 37.3328, longitude: -122.0296)]
        let viewModel = makeViewModel(
            playdates: [futurePlaydate, todayPlaydate],
            attendeesByEventID: [todayPlaydate.id: todayAttendees]
        )

        await viewModel.loadInterestedPlaydates()

        #expect(viewModel.interestedPlaydates.count == 2)
        #expect(viewModel.selectedPlaydate?.id == todayPlaydate.id)
        #expect(viewModel.selectedPlaydate?.pickerTitle == todayPlaydate.pickerTitle)
        #expect(viewModel.selectedInterestedPeople == todayAttendees)
    }

    @MainActor
    @Test func selectingPlaydateClearsExistingAttendeesBeforeLoadingNewOnes() async throws {
        let firstPlaydate = makePlaydate(
            title: "First",
            subtitle: "Today",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-04-26T16:30:00-07:00",
            endsAt: "2026-04-26T18:30:00-07:00",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let secondPlaydate = makePlaydate(
            title: "Second",
            subtitle: "Tomorrow",
            latitude: 37.3349,
            longitude: -122.0090,
            scheduledAt: "2026-05-02T11:15:00-07:00",
            endsAt: "2026-05-02T13:15:00-07:00",
            tintName: "orange",
            symbolName: "basket.fill"
        )
        let firstAttendees = [makeAttendee(id: "user-1", name: "Amy", latitude: 37.33, longitude: -122.03)]
        let secondAttendees = [makeAttendee(id: "user-2", name: "Lucas", latitude: 37.34, longitude: -122.01)]
        let viewModel = makeViewModel(
            playdates: [firstPlaydate, secondPlaydate],
            attendeesByEventID: [
                firstPlaydate.id: firstAttendees,
                secondPlaydate.id: secondAttendees
            ]
        )

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.selectedInterestedPeople == firstAttendees)

        viewModel.selectPlaydate(secondPlaydate.id)
        #expect(viewModel.selectedInterestedPeople.isEmpty)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(viewModel.selectedInterestedPeople == secondAttendees)
    }

    @MainActor
    @Test func askEveryTimeRemembersDeclineForEachEventUntilItEnds() async throws {
        let now = try #require(iso8601Date("2026-05-02T16:30:00Z"))
        let playdate = makePlaydate(
            title: "Playground",
            subtitle: "Today · 5:00 PM",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-05-02T17:00:00Z",
            endsAt: "2026-05-02T19:00:00Z",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let preferencesStore = MockLocationSharingPreferencesStore(selectedPreference: .askEveryTimeForEachEvent)
        let viewModel = makeViewModel(playdates: [playdate], preferencesStore: preferencesStore, now: now)

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.locationSharingPromptPlaydate?.id == playdate.id)

        viewModel.declineLocationSharing()
        #expect(preferencesStore.eventDecision(for: playdate.id, referenceDate: now) == .notNow)

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.locationSharingPromptPlaydate == nil)

        let afterEvent = try #require(iso8601Date("2026-05-02T19:30:00Z"))
        preferencesStore.cleanupExpiredDecisions(referenceDate: afterEvent)
        #expect(preferencesStore.eventDecision(for: playdate.id, referenceDate: afterEvent) == nil)
    }

    @MainActor
    @Test func approvingLocationSharingRemembersShareDecision() async throws {
        let now = try #require(iso8601Date("2026-05-02T16:30:00Z"))
        let playdate = makePlaydate(
            title: "Playground",
            subtitle: "Today · 5:00 PM",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-05-02T17:00:00Z",
            endsAt: "2026-05-02T19:00:00Z",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let preferencesStore = MockLocationSharingPreferencesStore(selectedPreference: .askEveryTimeForEachEvent)
        let viewModel = makeViewModel(playdates: [playdate], preferencesStore: preferencesStore, now: now)

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.locationSharingPromptPlaydate?.id == playdate.id)

        viewModel.approveLocationSharing()

        #expect(preferencesStore.eventDecision(for: playdate.id, referenceDate: now) == .share)
        #expect(viewModel.locationSharingPromptPlaydate == nil)
    }

    @MainActor
    @Test func alwaysSharePreferenceSkipsPromptForEligibleEvent() async throws {
        let now = try #require(iso8601Date("2026-05-02T16:30:00Z"))
        let playdate = makePlaydate(
            title: "Playground",
            subtitle: "Today · 5:00 PM",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-05-02T17:00:00Z",
            endsAt: "2026-05-02T19:00:00Z",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let preferencesStore = MockLocationSharingPreferencesStore(
            selectedPreference: .alwaysShareWhenPlaydateIsAboutToStart
        )
        let viewModel = makeViewModel(playdates: [playdate], preferencesStore: preferencesStore, now: now)

        await viewModel.loadInterestedPlaydates()

        #expect(viewModel.locationSharingPromptPlaydate == nil)
    }

    @MainActor
    @Test func attendeeLocationsRefreshEveryThirtySecondsUntilMapDisappears() async throws {
        let playdate = makePlaydate(
            title: "Playground",
            subtitle: "Today · 5:00 PM",
            latitude: 37.3317,
            longitude: -122.0325,
            scheduledAt: "2026-05-02T17:00:00Z",
            endsAt: "2026-05-02T19:00:00Z",
            tintName: "mint",
            symbolName: "house.fill"
        )
        let attendees = [makeAttendee(id: "user-1", name: "Amy", latitude: 37.33, longitude: -122.03)]
        let attendeeFetchSpy = AttendeeFetchSpy(attendeesByEventID: [playdate.id: attendees])
        let viewModel = makeViewModel(
            playdates: [playdate],
            attendeesByEventID: [playdate.id: attendees],
            attendeeFetchSpy: attendeeFetchSpy,
            attendeeRefreshInterval: .milliseconds(20)
        )

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.selectedInterestedPeople == attendees)

        try await Task.sleep(for: .milliseconds(75))
        #expect(await attendeeFetchSpy.callCount(for: playdate.id) >= 3)

        viewModel.onDisappear()

        let callCountBeforeWaiting = await attendeeFetchSpy.callCount(for: playdate.id)
        try await Task.sleep(for: .milliseconds(50))
        #expect(await attendeeFetchSpy.callCount(for: playdate.id) == callCountBeforeWaiting)
    }

    @MainActor
    @Test func signedOutMapDoesNotFetchPrivatePlaydates() async throws {
        let playdateFetchSpy = PlaydateFetchSpy()
        let viewModel = makeViewModel(
            playdates: [makePlaydate(
                title: "Playground",
                subtitle: "Today · 5:00 PM",
                latitude: 37.3317,
                longitude: -122.0325,
                scheduledAt: "2026-05-02T17:00:00Z",
                endsAt: "2026-05-02T19:00:00Z",
                tintName: "mint",
                symbolName: "house.fill"
            )],
            playdateFetchSpy: playdateFetchSpy,
            isAuthenticated: false
        )

        viewModel.onAppear(isLoggedIn: false)
        await viewModel.loadInterestedPlaydates()

        #expect(await playdateFetchSpy.fetchCount() == 0)
        #expect(viewModel.interestedPlaydates.isEmpty)
        #expect(viewModel.selectedPlaydate == nil)
    }

    @MainActor
    private func makeViewModel(
        playdates: [InterestedPlaydateMapDetail],
        attendeesByEventID: [UUID: [InterestedPersonLocation]] = [:],
        preferencesStore: LocationSharingPreferencesStoreProtocol = MockLocationSharingPreferencesStore(),
        now: Date = Date(),
        playdateFetchSpy: PlaydateFetchSpy? = nil,
        attendeeFetchSpy: AttendeeFetchSpy? = nil,
        attendeeRefreshInterval: Duration = .seconds(30),
        isAuthenticated: Bool = true
    ) -> HomeMapViewModel {
        HomeMapViewModel(
            interestedEventsRepository: MockInterestedEventsRepository(
                playdates: playdates,
                attendeesByEventID: attendeesByEventID,
                playdateFetchSpy: playdateFetchSpy,
                attendeeFetchSpy: attendeeFetchSpy
            ),
            locationRepository: MockLocationRepository(),
            locationSharingPreferencesStore: preferencesStore,
            currentDateProvider: { now },
            attendeeRefreshInterval: attendeeRefreshInterval,
            isAuthenticated: isAuthenticated
        )
    }

    private func makePlaydate(
        title: String,
        subtitle: String,
        latitude: Double,
        longitude: Double,
        scheduledAt: String,
        endsAt: String,
        tintName: String,
        symbolName: String
    ) -> InterestedPlaydateMapDetail {
        InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: title,
                subtitle: subtitle,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                tintName: tintName,
                symbolName: symbolName
            ),
            scheduledAt: iso8601Date(scheduledAt),
            endsAt: iso8601Date(endsAt),
            interestedPeople: []
        )
    }

    private func makeAttendee(id: String, name: String, latitude: Double, longitude: Double) -> InterestedPersonLocation {
        InterestedPersonLocation(
            id: id,
            name: name,
            locationName: "",
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }

    private func iso8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
