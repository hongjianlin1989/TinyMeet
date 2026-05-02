import Foundation
import Testing
@testable import TinyMeet

struct ProfileRespositoryTests {
    @Test func addFriendSucceedsWithMockData() async throws {
        let repository = ProfileRespository()

        try await repository.addFriend(
            UserProfile(
                id: "friend-999",
                username: "friendcandidate",
                displayName: "Friend Candidate",
                email: nil,
                bio: "Potential new friend",
                age: 30,
                avatarURL: nil
            )
        )
    }

    @Test func removeFriendSucceedsWithMockData() async throws {
        let repository = ProfileRespository()

        try await repository.removeFriend(
            UserProfile(
                id: "friend-999",
                username: "friendcandidate",
                displayName: "Friend Candidate",
                email: nil,
                bio: "Potential former friend",
                age: 30,
                avatarURL: nil
            )
        )
    }

    @Test func fetchUserProfileDecodesLiveApiShape() async throws {
        struct MockNetworkManager: NetworkManaging {
            let data: Data

            func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
                try JSONDecoder().decode(T.self, from: data)
            }
        }

        let payload = """
        {
          "id": "firebase-uid-123",
          "username": "hongjianlin1989",
          "display_name": "Hongjian Lin",
          "email": "hongjianlin@example.com",
          "bio": "Building TinyMeet.",
          "age": 36,
          "avatar_url": "https://example.com/avatar-hong.jpg",
          "created_at": "2026-04-28T12:00:00Z"
        }
        """

        let repository = ProfileRespository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let profile = try await repository.fetchUserProfile()
        #expect(profile.id == "firebase-uid-123")
        #expect(profile.username == "hongjianlin1989")
        #expect(profile.displayName == "Hongjian Lin")
        #expect(profile.email == "hongjianlin@example.com")
        #expect(profile.bio == "Building TinyMeet.")
    }

    @Test func fetchFriendProfilesDecodesFriendsArray() async throws {
        struct MockNetworkManager: NetworkManaging {
            let data: Data

            func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
                try JSONDecoder().decode(T.self, from: data)
            }
        }

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

        let repository = ProfileRespository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let friends = try await repository.fetchFriendProfiles()

        #expect(friends.count == 1)
        #expect(friends.first?.id == "friend-456")
        #expect(friends.first?.username == "friend-456")
        #expect(friends.first?.displayName == "Amy Chen")
        #expect(friends.first?.avatarURL?.absoluteString == "https://example.com/amy.jpg")
    }

    @Test func fetchFriendRequestsUsesMockJSONWhenAvailable() async throws {
        let bundleFixture = try makeMockBundle(
            resourceName: "mock_friend_requests",
            json: """
            {
              "items": [
                {
                  "id": "request-amychen",
                  "username": "amychen",
                  "display_name": "Amy Chen",
                  "bio": "Coffee meetup organizer.",
                  "age": 27,
                  "avatar_url": "https://example.com/amy.jpg"
                }
              ]
            }
            """
        )
        defer { bundleFixture.cleanup() }

        let repository = ProfileRespository(bundle: bundleFixture.bundle)

        let requests = try await repository.fetchFriendRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.username == "amychen")
    }

    @Test func fetchFriendRequestsUsesLiveAPIWhenMockDataDisabled() async throws {
        let payload = """
        {
          "items": [
            {
              "id": "request-noahpatel",
              "username": "noahpatel",
              "display_name": "Noah Patel",
              "bio": "Mobile engineer interested in SwiftUI.",
              "age": 29,
              "avatar_url": "https://example.com/noah.jpg"
            }
          ]
        }
        """

        let recorder = RequestRecorder()
        let repository = ProfileRespository(
            networkManager: RecordingNetworkManager(
                data: try #require(payload.data(using: .utf8)),
                recorder: recorder
            )
        )

        let requests = try await repository.fetchFriendRequests()
        let request = await recorder.lastRequest

        #expect(requests.count == 1)
        #expect(requests.first?.username == "noahpatel")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.path == "/api/v1/friends/requests")
    }

    @Test func searchUserProfilesUsesMockJSONWhenAvailable() async throws {
        let bundleFixture = try makeMockBundle(
            resourceName: "mock_search_profiles",
            json: """
            {
              "items": [
                {
                  "id": "101",
                  "username": "jsononlyuser",
                  "bio": "Climber meetup regular who loves weekend bouldering sessions.",
                  "age": 34,
                  "avatar_url": "https://example.com/jsononlyuser.jpg"
                },
                {
                  "id": "102",
                  "username": "quietreader",
                  "bio": null,
                  "age": 29,
                  "avatar_url": null
                }
              ]
            }
            """
        )
        defer { bundleFixture.cleanup() }

        let repository = ProfileRespository(bundle: bundleFixture.bundle)

        let results = try await repository.searchUserProfiles(query: "  climber ")
        #expect(results.count == 1)
        #expect(results.first?.username == "jsononlyuser")
    }

    @Test func searchUserProfilesReturnsEmptyForWhitespaceQuery() async throws {
        let bundleFixture = try makeMockBundle(
            resourceName: "mock_search_profiles",
            json: """
            {
              "items": [
                {
                  "id": "201",
                  "username": "someone",
                  "bio": "Has content but should not be searched for blank queries.",
                  "age": 24,
                  "avatar_url": null
                }
              ]
            }
            """
        )
        defer { bundleFixture.cleanup() }

        let repository = ProfileRespository(bundle: bundleFixture.bundle)

        let results = try await repository.searchUserProfiles(query: "   ")
        #expect(results.isEmpty)
    }

    @Test func searchUserProfilesUsesLiveSearchAPIWhenMockDataDisabled() async throws {
        let payload = """
        {
          "items": [
            {
              "id": "user-amychen",
              "username": "amychen",
              "display_name": "Amy Chen",
              "email": "amy@example.com",
              "bio": "Coffee meetup organizer.",
              "age": 27,
              "avatar_url": "https://example.com/amy.jpg"
            }
          ]
        }
        """

        let recorder = RequestRecorder()
        let repository = ProfileRespository(
            networkManager: RecordingNetworkManager(
                data: try #require(payload.data(using: .utf8)),
                recorder: recorder
            )
        )

        let results = try await repository.searchUserProfiles(query: "  amy chen  ")
        let request = await recorder.lastRequest

        #expect(results.count == 1)
        #expect(results.first?.username == "amychen")
        #expect(request?.httpMethod == "GET")
        #expect(request?.url?.path == "/api/v1/users/search")
        let queryItem = URLComponents(url: try #require(request?.url), resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "query" })
        #expect(queryItem?.value == "amy chen")
    }

    @Test func acceptFriendRequestUsesRespondAPIWhenMockDataDisabled() async throws {
        let recorder = RequestRecorder()
        let repository = ProfileRespository(
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

    @Test func rejectFriendRequestUsesRespondAPIWhenMockDataDisabled() async throws {
        let recorder = RequestRecorder()
        let repository = ProfileRespository(
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

    private func makeMockBundle(resourceName: String, json: String) throws -> TemporaryBundleFixture {
        let fileManager = FileManager.default
        let bundleURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("bundle")

        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let infoPlist: [String: Any] = [
            "CFBundleIdentifier": "com.tinymeet.tests.\(UUID().uuidString)",
            "CFBundleName": "MockProfilesFixture",
            "CFBundlePackageType": "BNDL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1"
        ]

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0
        )

        try plistData.write(to: bundleURL.appendingPathComponent("Info.plist"))
        try Data(json.utf8).write(to: bundleURL.appendingPathComponent("\(resourceName).json"))

        let bundle = try #require(Bundle(url: bundleURL))
        return TemporaryBundleFixture(url: bundleURL, bundle: bundle)
    }
}

private actor RequestRecorder {
    private(set) var lastRequest: URLRequest?

    func record(_ request: URLRequest) {
        lastRequest = request
    }
}

private struct RecordingNetworkManager: NetworkManaging {
    let data: Data
    let recorder: RequestRecorder

    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        await recorder.record(request)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct TemporaryBundleFixture {
    let url: URL
    let bundle: Bundle

    func cleanup() {
        try? FileManager.default.removeItem(at: url)
    }
}
