import Foundation
import Testing
@testable import TinyMeet

struct ProfileRespositoryTests {
    @Test func addFriendSucceedsWithMockData() async throws {
        let repository = ProfileRespository(shouldUseMockData: true)

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
        let repository = ProfileRespository(shouldUseMockData: true)

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
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let profile = try await repository.fetchUserProfile()
        #expect(profile.id == "firebase-uid-123")
        #expect(profile.username == "hongjianlin1989")
        #expect(profile.displayName == "Hongjian Lin")
        #expect(profile.email == "hongjianlin@example.com")
        #expect(profile.bio == "Building TinyMeet.")
    }

    @Test func searchUserProfilesUsesMockJSONWhenAvailable() async throws {
        let bundleFixture = try makeMockBundle(json: """
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
        """)
        defer { bundleFixture.cleanup() }

        let repository = ProfileRespository(shouldUseMockData: true, bundle: bundleFixture.bundle)

        let results = try await repository.searchUserProfiles(query: "  climber ")
        #expect(results.count == 1)
        #expect(results.first?.username == "jsononlyuser")
    }

    @Test func searchUserProfilesReturnsEmptyForWhitespaceQuery() async throws {
        let bundleFixture = try makeMockBundle(json: """
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
        """)
        defer { bundleFixture.cleanup() }

        let repository = ProfileRespository(shouldUseMockData: true, bundle: bundleFixture.bundle)

        let results = try await repository.searchUserProfiles(query: "   ")
        #expect(results.isEmpty)
    }

    @Test func searchUserProfilesUsesLiveSearchAPIWhenMockDataDisabled() async throws {
        actor RequestRecorder {
            private(set) var lastRequest: URLRequest?

            func record(_ request: URLRequest) {
                lastRequest = request
            }
        }

        struct MockNetworkManager: NetworkManaging {
            let data: Data
            let recorder: RequestRecorder

            func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
                await recorder.record(request)
                return try JSONDecoder().decode(T.self, from: data)
            }
        }

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
            networkManager: MockNetworkManager(
                data: try #require(payload.data(using: .utf8)),
                recorder: recorder
            ),
            shouldUseMockData: false
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

    private func makeMockBundle(json: String) throws -> TemporaryBundleFixture {
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
        try Data(json.utf8).write(to: bundleURL.appendingPathComponent("mock_search_profiles.json"))

        let bundle = try #require(Bundle(url: bundleURL))
        return TemporaryBundleFixture(url: bundleURL, bundle: bundle)
    }
}

private struct TemporaryBundleFixture {
    let url: URL
    let bundle: Bundle

    func cleanup() {
        try? FileManager.default.removeItem(at: url)
    }
}
