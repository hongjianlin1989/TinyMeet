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
    // swiftlint:disable function_body_length
    @Test func fetchInterestedEventsEnrichesPublicAndPrivateRecords() async throws {
        let publicEventID = try #require(UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1"))
        let privateEventID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
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
            eventsRepository: MockEventsRepository(publicEvents: [publicEvent], privateEvents: [privateEvent])
        )

        let rows = try await repository.fetchInterestedEvents()
        #expect(rows.count == 2)
        #expect(rows.contains(where: { $0.title == "Playground Picnic Crew" && $0.visibility == NearbyEventVisibility.public }))
        #expect(rows.contains(where: { $0.title == "Neighborhood Sandbox Circle" && $0.visibility == NearbyEventVisibility.private }))
    }
    // swiftlint:enable function_body_length

    @MainActor
    // swiftlint:disable function_body_length
    @Test func fetchInterestedPrivatePlaydatesUsesInterestedEventsPayloadAndFiltersToPrivateEvents() async throws {
        let publicInterestID = UUID()
        let publicEventID = UUID()
        let privateInterestID = UUID()
        let privateEventID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let personID = UUID()
        let payload = """
        {
          "events": [
            {
              "id": "\(publicInterestID.uuidString)",
              "event_id": "\(publicEventID.uuidString)",
              "event_type": "public",
              "uid": "user_public",
              "title": "Library Story Time",
              "subtitle": "Public meetup",
              "location_name": "Main Library",
              "latitude": 37.3300,
              "longitude": -122.0300,
              "created_at": "2026-04-25T16:30:00-07:00",
              "scheduled_at": "2026-04-27T10:00:00-07:00"
            },
            {
              "id": "\(privateInterestID.uuidString)",
              "event_id": "\(privateEventID.uuidString)",
              "event_type": "private",
              "uid": "user_amy",
              "title": "Backyard Playdate",
              "subtitle": "Oak Lane Backyard · Today · 4:30 PM",
              "location_name": "Oak Lane Backyard",
              "latitude": 37.3317,
              "longitude": -122.0325,
              "created_at": "2026-04-26T16:30:00-07:00",
              "scheduled_at": "2026-04-27T16:30:00-07:00",
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

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [])
        )

        let playdates = try await repository.fetchInterestedPrivatePlaydates()
        #expect(playdates.count == 1)

        let playdate = try #require(playdates.first)
        #expect(playdate.id == privateEventID)
        #expect(playdate.title == "Backyard Playdate")
        #expect(playdate.subtitle == "Oak Lane Backyard · Today · 4:30 PM")
        #expect(abs(playdate.coordinate.latitude - 37.3317) < 0.0001)
        #expect(abs(playdate.coordinate.longitude - (-122.0325)) < 0.0001)
        #expect(playdate.interestedPeople.count == 1)
        #expect(playdates.contains(where: { $0.id == publicEventID }) == false)

        let person = try #require(playdate.interestedPeople.first)
        #expect(person.id == personID)
        #expect(person.name == "Amy Chen")
        #expect(person.locationName == "Main Library")
    }
    // swiftlint:enable function_body_length

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
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        try await repository.setInterested(true, event: event)
        try await repository.setInterested(false, event: event)
    }
}
