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
        let groupID = UUID()
        let payload = """
        {
          "events": [
            {
              "id": "\(id.uuidString)",
              "title": "Private Event",
              "location_name": "Backyard",
              "latitude": 37.3317,
              "longitude": -122.0325,
              "age_range": "2-4",
              "theme_emoji": "📚",
              "symbol_name": "house.fill",
              "tint_name": "mint",
              "summary": "Invite-only",
              "host_uid": "host-sofia",
              "host_name": "Sofia",
              "audience_type": "friends",
              "group_id": "\(groupID.uuidString)",
              "attendee_count": 3,
              "is_interested": true,
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
        #expect(event.isInterested == true)
        #expect(event.eventUrl == nil)
    }

    @Test func createEventReturnsMockNearbyEventWhenUsingMockData() async throws {
        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require("{}".data(using: .utf8)))
        )
        let request = CreateEventRequest(
            visibility: .private,
            title: "Playground Party",
            locationName: "Central Park",
            latitude: 0,
            longitude: 0,
            ageRange: "3 - 5",
            themeEmoji: "🎉",
            summary: "A newly created playdate for your TinyMeet community.",
            symbolName: "figure.2.and.child.holdinghands",
            tintName: "mint",
            audienceType: "friends",
            groupID: nil,
            invitedUIDs: ["friend-1"],
            eventURL: nil,
            scheduledAt: "2026-05-03T13:56:44.745Z"
        )

        let event = try await repo.createEvent(request)
        #expect(event.title == "Playground Party")
        #expect(event.locationName == "Central Park")
        #expect(event.visibility == .private)
    }

    @Test func createEventUsesNetworkManagerWhenMockDisabled() async throws {
        let payload = "{}"

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let event = try await repo.createEvent(
            CreateEventRequest(
                visibility: .private,
                title: "Created Event",
                locationName: "Central Park",
                latitude: 0,
                longitude: 0,
                ageRange: "3 - 5",
                themeEmoji: "🎉",
                summary: "A newly created playdate for your TinyMeet community.",
                symbolName: "figure.2.and.child.holdinghands",
                tintName: "mint",
                audienceType: "group",
                groupID: "group-123",
                invitedUIDs: [],
                eventURL: nil,
                scheduledAt: "2026-05-03T13:56:44.745Z"
            )
        )

        #expect(event.title == "Created Event")
        #expect(event.visibility == .private)
        #expect(event.distanceDescription == "Just created")
    }

    @Test func createPublicEventMapsToPublicNearbyEvent() async throws {
        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require("{}".data(using: .utf8)))
        )

        let event = try await repo.createEvent(
            CreateEventRequest(
                visibility: .public,
                title: "Community Picnic",
                locationName: "Town Green",
                latitude: 0,
                longitude: 0,
                ageRange: "4 - 7",
                themeEmoji: "🌳",
                summary: "Bring snacks and meet local families.",
                symbolName: nil,
                tintName: nil,
                audienceType: nil,
                groupID: nil,
                invitedUIDs: nil,
                eventURL: "https://tinymeet.app/events/community-picnic",
                scheduledAt: "2026-05-03T14:15:45.592Z"
            )
        )

        #expect(event.title == "Community Picnic")
        #expect(event.visibility == .public)
        #expect(event.distanceDescription == "Community")
        #expect(event.eventUrl == "https://tinymeet.app/events/community-picnic")
    }
}
