import Foundation
import Testing
@testable import TinyMeet

struct FriendsRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    actor RequestRecorder {
        private(set) var lastRequest: URLRequest?

        func record(_ request: URLRequest) {
            lastRequest = request
        }
    }

    struct RecordingNetworkManager: NetworkManaging {
        let data: Data
        let recorder: RequestRecorder

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            await recorder.record(request)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func fetchFriendProfilesDecodesFriendsArray() async throws {
        let payload = """
        {
          "friends": [
            {
              "uid": "owner-123",
              "friend_uid": "friend-456",
              "display_name": "Amy Chen",
              "avatar_url": "https://example.com/amy.jpg",
              "created_at": "2026-05-02T15:13:08.220Z"
            }
          ]
        }
        """

        let repository = FriendsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let friends = try await repository.fetchFriendProfiles()

        #expect(friends.count == 1)
        #expect(friends.first?.id == "friend-456")
        #expect(friends.first?.username == "friend-456")
        #expect(friends.first?.displayName == "Amy Chen")
        #expect(friends.first?.avatarURL?.absoluteString == "https://example.com/amy.jpg")
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

        let repository = FriendsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let requests = try await repository.fetchFriendRequests()

        #expect(requests.count == 1)
        #expect(requests.first?.id == "999d5771-4db1-4a26-8ad5-08a3e3be6894")
        #expect(requests.first?.username == "u581lbetLMNYZCfaOk3X7SVzkWe2")
        #expect(requests.first?.displayName == "u581lbetLMNYZCfaOk3X7SVzkWe2")
    }

    @Test func addFriendUsesFriendRequestsEndpointAndBody() async throws {
        let recorder = RequestRecorder()
        let repository = FriendsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{\"success\":true}".data(using: .utf8)),
                recorder: recorder
            )
        )

        try await repository.addFriend(
            UserProfile(
                id: "friend-42",
                username: "amychen",
                displayName: "Amy Chen",
                email: nil,
                bio: nil,
                age: nil,
                avatarURL: nil
            )
        )

        let request = await recorder.lastRequest
        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.path == "/api/v1/friends/requests")
        let body = try #require(request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["receiver_uid"] == "friend-42")
    }

    @Test func removeFriendUsesDeleteFriendsEndpoint() async throws {
        let recorder = RequestRecorder()
        let repository = FriendsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{\"success\":true}".data(using: .utf8)),
                recorder: recorder
            )
        )

        try await repository.removeFriend(
            UserProfile(
                id: "friend-42",
                username: "amychen",
                displayName: "Amy Chen",
                email: nil,
                bio: nil,
                age: nil,
                avatarURL: nil
            )
        )

        let request = await recorder.lastRequest
        #expect(request?.httpMethod == "DELETE")
        #expect(request?.url?.path == "/api/v1/friends/friend-42")
    }

    @Test func acceptFriendRequestUsesRespondAPI() async throws {
        let recorder = RequestRecorder()
        let repository = FriendsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{\"success\":true}".data(using: .utf8)),
                recorder: recorder
            )
        )

        let requestProfile = UserProfile(
            id: "request-42",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )

        try await repository.acceptFriendRequest(requestProfile)
        let request = await recorder.lastRequest

        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.path == "/api/v1/friends/requests/request-42/respond")
        let body = try #require(request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Bool])
        #expect(json["accept"] == true)
    }

    @Test func rejectFriendRequestUsesRespondAPI() async throws {
        let recorder = RequestRecorder()
        let repository = FriendsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{\"success\":true}".data(using: .utf8)),
                recorder: recorder
            )
        )

        let requestProfile = UserProfile(
            id: "request-99",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )

        try await repository.rejectFriendRequest(requestProfile)
        let request = await recorder.lastRequest

        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.path == "/api/v1/friends/requests/request-99/respond")
        let body = try #require(request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Bool])
        #expect(json["accept"] == false)
    }
}
