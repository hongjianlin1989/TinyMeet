import Foundation
import Testing
@testable import TinyMeet

struct ProfileRespositoryTests {
    @Test func addFriendSucceedsWithMockData() async throws {
        let repository = ProfileRespository(shouldUseMockData: true)

        try await repository.addFriend(
            UserProfile(
                id: 999,
                username: "friendcandidate",
                bio: "Potential new friend",
                age: 30,
                avatarURL: nil
            )
        )
    }

    @Test func searchUserProfilesUsesMockJSONWhenAvailable() async throws {
        let bundleFixture = try makeMockBundle(json: """
        {
          "items": [
            {
              "id": 101,
              "username": "jsononlyuser",
              "bio": "Climber meetup regular who loves weekend bouldering sessions.",
              "age": 34,
              "avatar_url": "https://example.com/jsononlyuser.jpg"
            },
            {
              "id": 102,
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
              "id": 201,
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
