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
          "items": [
            {
              "id": "\(id.uuidString)",
              "title": "Public Event",
              "locationName": "Central Park",
              "timeDescription": "Today",
              "ageRange": "3-5",
              "distanceDescription": "0.5 mi",
              "hostName": "Mia",
              "attendeeSummary": "8 families",
              "themeEmoji": "🛝",
              "summary": "Fun",
              "eventUrl": "https://tinymeet.app/events/public-event"
            }
          ]
        }
        """

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let events = try await repo.fetchPublicEvents()
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.id == id)
        #expect(event.visibility == .public)
        #expect(event.title == "Public Event")
        #expect(event.eventUrl == "https://tinymeet.app/events/public-event")
    }

    @Test func fetchPrivateEventsDecodesAndAppliesPrivateVisibility() async throws {
        let id = UUID()
        let payload = """
        {
          "items": [
            {
              "id": "\(id.uuidString)",
              "title": "Private Event",
              "locationName": "Backyard",
              "timeDescription": "Tomorrow",
              "ageRange": "2-4",
              "distanceDescription": "1.0 mi",
              "hostName": "Sofia",
              "attendeeSummary": "3 families",
              "themeEmoji": "📚",
              "summary": "Invite-only"
            }
          ]
        }
        """

        let repo = EventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let events = try await repo.fetchPrivateEvents()
        #expect(events.count == 1)
        let event = try #require(events.first)
        #expect(event.id == id)
        #expect(event.visibility == .private)
        #expect(event.title == "Private Event")
        #expect(event.eventUrl == nil)
    }
}
