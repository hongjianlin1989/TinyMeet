import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct HomeMapViewModelTests {
    struct MockInterestedEventsRepository: InterestedEventsRepositoryProtocol {
        let playdates: [InterestedPlaydateMapDetail]
        let attendeesByEventID: [UUID: [InterestedPersonLocation]]

        func fetchInterestedEvents() async throws -> [InterestedEventRow] {
            []
        }

        func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
            playdates
        }

        func fetchPrivateEventAttendees(eventID: UUID) async throws -> [InterestedPersonLocation] {
            attendeesByEventID[eventID] ?? []
        }

        func setInterested(_ isInterested: Bool, event: NearbyEvent) async throws {}
    }

    struct MockLocationRepository: LocationRepositoryProtocol {
        let onUpdate: @Sendable (Double, Double) async throws -> Void

        init(onUpdate: @escaping @Sendable (Double, Double) async throws -> Void = { _, _ in }) {
            self.onUpdate = onUpdate
        }

        func updateCurrentLocation(latitude: Double, longitude: Double) async throws {
            try await onUpdate(latitude, longitude)
        }
    }

    actor UploadedLocationsRecorder {
        private(set) var uploadedLocations: [(Double, Double)] = []

        func record(latitude: Double, longitude: Double) {
            uploadedLocations.append((latitude, longitude))
        }
    }

    @MainActor
    // swiftlint:disable function_body_length
    @Test func selectingPlaydateClearsExistingAttendeesBeforeLoadingNewOnes() async throws {
        let firstPlaydate = InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: "First",
                subtitle: "Today",
                coordinate: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
                tintName: "mint",
                symbolName: "house.fill"
            ),
            scheduledAt: iso8601Date("2026-04-26T16:30:00-07:00"),
            endsAt: iso8601Date("2026-04-26T18:30:00-07:00"),
            interestedPeople: []
        )
        let secondPlaydate = InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: "Second",
                subtitle: "Tomorrow",
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                tintName: "orange",
                symbolName: "basket.fill"
            ),
            scheduledAt: iso8601Date("2026-05-02T11:15:00-07:00"),
            endsAt: iso8601Date("2026-05-02T13:15:00-07:00"),
            interestedPeople: []
        )
        let firstAttendees = [
            InterestedPersonLocation(
                id: "user-1",
                name: "Amy",
                locationName: "",
                coordinate: CLLocationCoordinate2D(latitude: 37.33, longitude: -122.03)
            )
        ]
        let secondAttendees = [
            InterestedPersonLocation(
                id: "user-2",
                name: "Lucas",
                locationName: "",
                coordinate: CLLocationCoordinate2D(latitude: 37.34, longitude: -122.01)
            )
        ]

        let viewModel = HomeMapViewModel(
            interestedEventsRepository: MockInterestedEventsRepository(
                playdates: [firstPlaydate, secondPlaydate],
                attendeesByEventID: [
                    firstPlaydate.id: firstAttendees,
                    secondPlaydate.id: secondAttendees
                ]
            )
        )

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.selectedInterestedPeople == firstAttendees)

        viewModel.selectPlaydate(secondPlaydate.id)
        #expect(viewModel.selectedInterestedPeople.isEmpty)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(viewModel.selectedInterestedPeople == secondAttendees)
    }
    // swiftlint:enable function_body_length

    @MainActor
    @Test func selectingPlaydateWithinSharingWindowPromptsForLocationSharingAndUploadsAfterApproval() async throws {
        let now = try #require(iso8601Date("2026-05-02T16:30:00Z"))
        let playdate = InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: "Playground",
                subtitle: "Today · 5:00 PM",
                coordinate: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
                tintName: "mint",
                symbolName: "house.fill"
            ),
            scheduledAt: try #require(iso8601Date("2026-05-02T17:00:00Z")),
            endsAt: try #require(iso8601Date("2026-05-02T19:00:00Z")),
            interestedPeople: []
        )
        let recorder = UploadedLocationsRecorder()

        let locationManager = LocationManager()
        let viewModel = HomeMapViewModel(
            locationManager: locationManager,
            interestedEventsRepository: MockInterestedEventsRepository(
                playdates: [playdate],
                attendeesByEventID: [:]
            ),
            locationRepository: MockLocationRepository(onUpdate: { latitude, longitude in
                await recorder.record(latitude: latitude, longitude: longitude)
            }),
            currentDateProvider: { now }
        )

        await viewModel.loadInterestedPlaydates()
        #expect(viewModel.locationSharingPromptPlaydate?.id == playdate.id)

        viewModel.approveLocationSharing()
        #expect(viewModel.locationSharingPromptPlaydate == nil)
    }

    private func iso8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
