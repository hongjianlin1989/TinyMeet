import Foundation
import Testing
@testable import TinyMeet

struct ProfileUrlRequestTests {
    @Test func addFriendRequestUsesFriendsEndpoint() {
        let request = ProfileUrlRequest.addFriend(userID: 42).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/users/42/friends")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func removeFriendRequestUsesDeleteFriendsEndpoint() {
        let request = ProfileUrlRequest.removeFriend(userID: 42).asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/users/42/friends")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
