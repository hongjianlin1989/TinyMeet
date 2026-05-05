import Foundation
import Testing
@testable import TinyMeet

struct ProfileRespositoryTests {
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

    @Test func searchUserProfilesReturnsEmptyForWhitespaceQuery() async throws {
        let repository = ProfileRespository()

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
