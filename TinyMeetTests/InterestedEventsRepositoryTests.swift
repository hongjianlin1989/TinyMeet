import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct InterestedEventsRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    struct MockEventsRepository: EventsRepositoryProtocol {
        let publicEvents: [NearbyEvent]
        let privateEvents: [NearbyEvent]

        func fetchPublicEvents() async throws -> [NearbyEvent] {
            publicEvents
        }

        func fetchPrivateEvents() async throws -> [NearbyEvent] {
            privateEvents
        }

        func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
            request.toNearbyEvent()
        }
    }

    @MainActor
    @Test func fetchInterestedEventsEnrichesPublicAndPrivateRecords() async throws {
        let publicEventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let privateEventID = UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F")!
        let payload = """
        {
          "events": [
            {
              "id": "2C5A7E61-9B7D-4E10-9ED6-6BE2CDB9D1B1",
              "event_id": "\(publicEventID.uuidString)",
              "event_type": "public",
              "uid": "user_amy",
              "location_name": "Central Park Playground",
              "created_at": "2026-05-01T18:00:00Z"
            },
            {
              "id": "4D0D7EC9-3F8A-4F05-AF3C-9DDE7E61B61B",
              "event_id": "\(privateEventID.uuidString)",
              "event_type": "private",
              "uid": "user_brian",
              "location_name": "Oak Lane Backyard",
              "created_at": "2026-05-01T18:05:00Z"
            }
          ]
        }
        """

        let publicEvent = NearbyEvent(
            id: publicEventID,
            title: "Playground Picnic Crew",
            locationName: "Central Park Playground",
            timeDescription: "Today · 4:00 PM",
            ageRange: "Ages 3-5",
            distanceDescription: "0.4 mi away",
            hostName: "Hosted by Mia",
            attendeeSummary: "8 families going",
            themeEmoji: "🛝",
            summary: "Meet other families for snacks.",
            eventUrl: "https://tinymeet.app/events/playground-picnic-crew",
            visibility: .public
        )

        let privateEvent = NearbyEvent(
            id: privateEventID,
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            visibility: .private
        )

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            eventsRepository: MockEventsRepository(publicEvents: [publicEvent], privateEvents: [privateEvent]),
            shouldUseMockData: false
        )

        let rows = try await repository.fetchInterestedEvents()
        #expect(rows.count == 2)
        #expect(rows.contains(where: { $0.title == "Playground Picnic Crew" && $0.visibility == .public }))
        #expect(rows.contains(where: { $0.title == "Neighborhood Sandbox Circle" && $0.visibility == .private }))
    }

    @MainActor
    @Test func fetchInterestedPrivatePlaydatesDecodesCoordinatesAndPeople() async throws {
        let interestID = UUID()
        let eventID = UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F")!
        let personID = UUID()
        let payload = """
        {
          "events": [
            {
              "id": "\(interestID.uuidString)",
              "event_id": "\(eventID.uuidString)",
              "event_type": "private",
              "uid": "user_amy",
              "location_name": "Oak Lane Backyard",
              "latitude": 37.3317,
              "longitude": -122.0325,
              "created_at": "2026-04-26T16:30:00-07:00",
              "symbol_name": "house.fill",
              "tint_name": "mint",
              "interested_people": [
                {
                  "id": "\(personID.uuidString)",
                  "name": "Amy Chen",
                  "locationName": "Main Library",
                  "latitude": 37.3328,
                  "longitude": -122.0296
                }
              ]
            }
          ]
        }
        """

        let privateEvent = NearbyEvent(
            id: eventID,
            title: "Backyard Playdate",
            locationName: "Oak Lane Backyard",
            timeDescription: "Today · 4:30 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            visibility: .private
        )

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [privateEvent]),
            shouldUseMockData: false
        )

        let playdates = try await repository.fetchInterestedPrivatePlaydates()
        #expect(playdates.count == 1)

        let playdate = try #require(playdates.first)
        #expect(playdate.id == eventID)
        #expect(playdate.title == "Backyard Playdate")
        #expect(abs(playdate.coordinate.latitude - 37.3317) < 0.0001)
        #expect(abs(playdate.coordinate.longitude - (-122.0325)) < 0.0001)
        #expect(playdate.interestedPeople.count == 1)

        let person = try #require(playdate.interestedPeople.first)
        #expect(person.id == personID)
        #expect(person.name == "Amy Chen")
        #expect(person.locationName == "Main Library")
    }

    @MainActor
    @Test func setInterestedAndUninterestedUseMutationRequests() async throws {
        let eventID = UUID()
        let event = NearbyEvent(
            id: eventID,
            title: "Backyard Playdate",
            locationName: "Oak Lane Backyard",
            timeDescription: "Today · 4:30 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            visibility: .private
        )
        let payload = """
        {
          "id": "\(UUID().uuidString)",
          "event_id": "\(eventID.uuidString)",
          "event_type": "private"
        }
        """

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        try await repository.setInterested(true, event: event)
        try await repository.setInterested(false, event: event)
    }
}
