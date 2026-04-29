import Foundation
import Testing
@testable import TinyMeet

struct ProfileUrlRequestTests {
    @Test func getUserProfileRequestUsesApiV1ProfileEndpoint() {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/users/profile")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func searchProfilesRequestUsesSearchEndpointAndEncodedQuery() {
        let request = ProfileUrlRequest.searchProfiles(query: "amy chen").asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/users/search")
        #expect(URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "query" })?.value == "amy chen")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func addFriendRequestUsesFriendsEndpoint() {
        let request = ProfileUrlRequest.addFriend(userID: "friend-42").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/users/friend-42/friends")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func removeFriendRequestUsesDeleteFriendsEndpoint() {
        let request = ProfileUrlRequest.removeFriend(userID: "friend-42").asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/users/friend-42/friends")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
