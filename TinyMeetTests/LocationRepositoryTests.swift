import Foundation
import Testing
@testable import TinyMeet

struct LocationRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func updateCurrentLocationSucceedsWithMockData() async throws {
        let repository = LocationRepository(shouldUseMockData: true)

        try await repository.updateCurrentLocation(latitude: 37.3317, longitude: -122.0325)
    }

    @Test func updateCurrentLocationUsesNetworkManagerWhenMockDisabled() async throws {
        let payload = "{}"
        let repository = LocationRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        try await repository.updateCurrentLocation(latitude: 37.3317, longitude: -122.0325)
    }
}
