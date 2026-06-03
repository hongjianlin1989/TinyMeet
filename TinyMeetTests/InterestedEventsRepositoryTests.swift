// swiftlint:disable file_length
import CoreLocation
import Foundation
@testable import TinyMeet
import Testing

struct InterestedEventsRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let handler: @Sendable (URLRequest) throws -> Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            let data = try handler(request)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    struct MockEventsRepository: EventsRepositoryProtocol {
        let publicEvents: [NearbyEvent]
        let privateEvents: [NearbyEvent]

        func fetchPublicEvents() async throws -> [NearbyEvent] { publicEvents }
        func fetchPrivateEvents() async throws -> [NearbyEvent] { privateEvents }
        func fetchUnifiedFeed(
            types: [String]?,
            categories: [String]?,
            ageGroups: [String]?,
            postalCode: String?,
            cursor: String?
        ) async throws -> (events: [NearbyEvent], nextCursor: String?) {
            (publicEvents + privateEvents, nil)
        }
        func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent { request.toNearbyEvent() }
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
            networkManager: MockNetworkManager(handler: { _ in try #require(payload.data(using: .utf8)) }),
            eventsRepository: MockEventsRepository(publicEvents: [publicEvent], privateEvents: [privateEvent])
        )

        let rows = try await repository.fetchInterestedEvents()
        #expect(rows.count == 2)
        #expect(rows.contains(where: { $0.title == "Playground Picnic Crew" && $0.visibility == .public }))
        #expect(rows.contains(where: { $0.title == "Neighborhood Sandbox Circle" && $0.visibility == .private }))
    }
    // swiftlint:enable function_body_length

    @MainActor
    @Test func fetchPrivateEventAttendeesUsesPrivateEventTypeQuery() async throws {
        let eventID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let payload = """
        {
          "attendees": [
            {
              "uid": "user_amy",
              "display_name": "Amy Chen",
              "avatar_url": "https://example.com/amy.png",
              "latitude": 37.3328,
              "longitude": -122.0296,
              "updated_at": "2026-05-09T14:36:56.493Z"
            }
          ]
        }
        """

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(handler: { request in
                let url = try #require(request.url)
                let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
                #expect(url.path == "/api/v1/events/\(eventID.uuidString)/attendees")
                #expect(components.queryItems?.first(where: { $0.name == "event_type" })?.value == "private")
                return try #require(payload.data(using: .utf8))
            }),
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [])
        )

        let attendees = try await repository.fetchPrivateEventAttendees(eventID: eventID)
        #expect(attendees.count == 1)
        #expect(attendees.first?.id == "user_amy")
        #expect(attendees.first?.name == "Amy Chen")
        #expect(abs((attendees.first?.coordinate.latitude ?? 0) - 37.3328) < 0.0001)
        #expect(abs((attendees.first?.coordinate.longitude ?? 0) - (-122.0296)) < 0.0001)
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
            networkManager: MockNetworkManager(handler: { _ in try #require(payload.data(using: .utf8)) })
        )

        try await repository.setInterested(true, event: event)
        try await repository.setInterested(false, event: event)
    }
}
