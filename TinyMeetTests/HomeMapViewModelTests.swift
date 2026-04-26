import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct HomeMapViewModelTests {
    struct MockInterestedEventsRepository: InterestedEventsRepositoryProtocol {
        let playdates: [InterestedPlaydateMapDetail]

        func fetchInterestedEvents() async throws -> [InterestedEventRow] {
            []
        }

        func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
            playdates
        }
    }

    @MainActor
    @Test func loadInterestedPlaydatesDefaultsToNearestScheduledPlaydate() async throws {
        let todayPlaydate = InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: "Today Playdate",
                subtitle: "Today · 4:30 PM",
                coordinate: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
                tintName: "mint",
                symbolName: "house.fill"
            ),
            scheduledAt: try #require(iso8601Date("2026-04-26T16:30:00-07:00")),
            interestedPeople: [
                InterestedPersonLocation(
                    name: "Amy Chen",
                    locationName: "Main Library",
                    coordinate: CLLocationCoordinate2D(latitude: 37.3328, longitude: -122.0296)
                )
            ]
        )

        let futurePlaydate = InterestedPlaydateMapDetail(
            event: PrivateEventMapItem(
                id: UUID(),
                title: "Future Playdate",
                subtitle: "Saturday · 11:15 AM",
                coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                tintName: "orange",
                symbolName: "basket.fill"
            ),
            scheduledAt: try #require(iso8601Date("2026-05-02T11:15:00-07:00")),
            interestedPeople: [
                InterestedPersonLocation(
                    name: "Lucas Kim",
                    locationName: "Community Garden",
                    coordinate: CLLocationCoordinate2D(latitude: 37.3360, longitude: -122.0100)
                )
            ]
        )

        let viewModel = HomeMapViewModel(
            interestedEventsRepository: MockInterestedEventsRepository(playdates: [futurePlaydate, todayPlaydate])
        )

        await viewModel.loadInterestedPlaydates()

        #expect(viewModel.interestedPlaydates.count == 2)
        #expect(viewModel.selectedPlaydate?.id == todayPlaydate.id)
        #expect(viewModel.selectedInterestedPeople.count == 1)
        #expect(viewModel.selectedInterestedPeople.first?.name == "Amy Chen")
    }

    private func iso8601Date(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }
}
