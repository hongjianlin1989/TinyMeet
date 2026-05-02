import Foundation
import Testing
@testable import TinyMeet

struct FriendRequestsRepositoryDecodingTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func fetchFriendRequestsDecodesTopLevelArrayResponse() async throws {
        let payload = """
        [
          {
            "id": "999d5771-4db1-4a26-8ad5-08a3e3be6894",
            "requester_uid": "u581lbetLMNYZCfaOk3X7SVzkWe2",
            "receiver_uid": "mock-a-a",
            "status": "pending",
            "created_at": "2026-05-02T14:24:25.022440Z",
            "responded_at": null
          }
        ]
        """

        let repository = ProfileRespository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let requests = try await repository.fetchFriendRequests()

        #expect(requests.count == 1)
        #expect(requests.first?.id == "999d5771-4db1-4a26-8ad5-08a3e3be6894")
        #expect(requests.first?.username == "u581lbetLMNYZCfaOk3X7SVzkWe2")
        #expect(requests.first?.displayName == "u581lbetLMNYZCfaOk3X7SVzkWe2")
    }
}
