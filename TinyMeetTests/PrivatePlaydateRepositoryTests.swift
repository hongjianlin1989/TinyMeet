import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct PrivatePlaydateRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func fetchPrivatePlaydatesDecodesAndMapsToMapItems() async throws {
        let id = UUID()
        let payload = """
        {
          "items": [
            {
              "id": "\(id.uuidString)",
              "title": "Test Playdate",
              "subtitle": "Today · 5:00 PM",
              "latitude": 37.3317,
              "longitude": -122.0325086,
              "tintName": "mint",
              "symbolName": "house.fill"
            }
          ]
        }
        """

        let networkManager = MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        let repository = PrivatePlaydateRepository(networkManager: networkManager, shouldUseMockData: false)

        let results = try await repository.fetchPrivatePlaydates()
        #expect(results.count == 1)

        let event = try #require(results.first)
        #expect(event.id == id)
        #expect(event.title == "Test Playdate")
        #expect(event.subtitle == "Today · 5:00 PM")
        #expect(event.tintName == "mint")
        #expect(event.symbolName == "house.fill")
        #expect(abs(event.coordinate.latitude - 37.3317) < 0.0001)
        #expect(abs(event.coordinate.longitude - (-122.0325086)) < 0.0001)
    }
}
