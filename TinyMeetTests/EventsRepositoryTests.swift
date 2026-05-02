import Foundation
import Testing
@testable import TinyMeet

struct EventsRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func fetchPublicEventsDecodesAndAppliesPublicVisibility() async throws {
        let id = UUID()
        let payload = """
        {
          "events": [
            {
              "id": "\(id.uuidString)",
              "title": "Public Event",
              "location_name": "Central Park",
              "age_range": "3-5",
              "theme_emoji": "🛝",
              "summary": "Fun",
              "event_url": "https://tinymeet.app/events/public-event",
              "host_name": "Mia",
              "attendee_count": 8,
              "scheduled_at": "2026-04-28T16:00:00Z",
              "created_at": "2026-04-27T16:00:00Z"
            }
          ]
        }
        """

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let events = try await repo.fetchPublicEvents()
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.id == id)
        #expect(event.visibility == .public)
        #expect(event.title == "Public Event")
        #expect(event.locationName == "Central Park")
        #expect(event.hostName == "Hosted by Mia")
        #expect(event.attendeeSummary == "8 people attending")
        #expect(event.eventUrl == "https://tinymeet.app/events/public-event")
    }

    @Test func fetchPrivateEventsDecodesAndAppliesPrivateVisibility() async throws {
        let id = UUID()
        let payload = """
        {
          "events": [
            {
              "id": "\(id.uuidString)",
              "title": "Private Event",
              "location_name": "Backyard",
              "age_range": "2-4",
              "theme_emoji": "📚",
              "summary": "Invite-only",
              "host_name": "Sofia",
              "audience_type": "friends",
              "attendee_count": 3,
              "scheduled_at": "2026-04-29T16:00:00Z",
              "created_at": "2026-04-27T16:00:00Z"
            }
          ]
        }
        """

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let events = try await repo.fetchPrivateEvents()
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.id == id)
        #expect(event.visibility == .private)
        #expect(event.title == "Private Event")
        #expect(event.distanceDescription == "Friends")
        #expect(event.hostName == "Hosted by Sofia")
        #expect(event.eventUrl == nil)
    }

    @Test func createEventReturnsMockNearbyEventWhenUsingMockData() async throws {
        let repo = EventsRepository()
        let request = CreateEventRequest(
            title: "Playground Party",
            locationName: "Central Park",
            timeDescription: "Tomorrow 3pm",
            ageRange: "3 - 5",
            joinVisibility: "friends"
        )

        let event = try await repo.createEvent(request)
        #expect(event.title == "Playground Party")
        #expect(event.locationName == "Central Park")
        #expect(event.visibility == .private)
    }

    @Test func createEventUsesNetworkManagerWhenMockDisabled() async throws {
        let id = UUID()
        let payload = """
        {
          "id": "\(id.uuidString)",
          "title": "Created Event",
          "locationName": "Central Park",
          "timeDescription": "Tomorrow 3pm",
          "ageRange": "3 - 5",
          "distanceDescription": "0.0 mi",
          "hostName": "Hosted by You",
          "attendeeSummary": "New public event",
          "themeEmoji": "🎉",
          "summary": "A newly created playdate for your TinyMeet community.",
          "eventUrl": null
        }
        """

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let event = try await repo.createEvent(
            CreateEventRequest(
                title: "Created Event",
                locationName: "Central Park",
                timeDescription: "Tomorrow 3pm",
                ageRange: "3 - 5",
                joinVisibility: "public"
            )
        )

        #expect(event.id == id)
        #expect(event.title == "Created Event")
        #expect(event.visibility == .public)
    }
}
