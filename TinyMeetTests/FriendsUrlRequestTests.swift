import Foundation
import Testing
@testable import TinyMeet

struct FriendsUrlRequestTests {
    @Test func friendRequestsRequestUsesApiV1FriendRequestsEndpoint() {
        let request = FriendsUrlRequest.friendRequests.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/friends/requests")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func friendsRequestUsesApiV1FriendsEndpoint() {
        let request = FriendsUrlRequest.friends.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/friends")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func respondToFriendRequestUsesRespondEndpointAndBody() throws {
        let request = FriendsUrlRequest
            .respondToFriendRequest(requestID: "request-42", action: .accept)
            .asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/friends/requests/request-42/respond")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Bool])
        #expect(json["accept"] == true)
    }

    @Test func addFriendRequestUsesFriendRequestsEndpointAndBody() throws {
        let request = FriendsUrlRequest.addFriend(userID: "friend-42").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/friends/requests")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["receiver_uid"] == "friend-42")
    }

    @Test func removeFriendRequestUsesDeleteFriendsEndpoint() {
        let request = FriendsUrlRequest.removeFriend(userID: "friend-42").asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/api/v1/friends/friend-42")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
