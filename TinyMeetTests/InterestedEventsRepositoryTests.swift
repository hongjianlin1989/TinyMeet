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

    @Test func fetchInterestedEventsDecodesResponse() async throws {
        let payload = """
        {
          "items": [
            {
              "id": "2C5A7E61-9B7D-4E10-9ED6-6BE2CDB9D1B1",
              "kind": "nearby",
              "visibility": "public",
              "title": "Playground Picnic Crew",
              "subtitle": "Central Park Playground · Today · 4:00 PM",
              "symbolName": "calendar"
            },
            {
              "id": "4D0D7EC9-3F8A-4F05-AF3C-9DDE7E61B61B",
              "kind": "privateMap",
              "visibility": "private",
              "title": "Backyard Playdate",
              "subtitle": "Today · 4:30 PM",
              "symbolName": "house.fill"
            }
          ]
        }
        """

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let rows = try await repository.fetchInterestedEvents()
        #expect(rows.count == 2)
        #expect(rows.contains(where: { $0.title == "Playground Picnic Crew" && $0.visibility == .public }))
        #expect(rows.contains(where: { $0.title == "Backyard Playdate" && $0.visibility == .private }))
    }
}
