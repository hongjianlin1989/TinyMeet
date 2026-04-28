import Foundation
import Testing
@testable import TinyMeet

struct GroupUrlRequestTests {
    @Test func listRequestUsesGroupsEndpoint() throws {
        let request = try GroupUrlRequest.list.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/groups")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == ApiConfig.timeoutInterval)
    }

    @Test func detailRequestUsesGroupDetailEndpoint() throws {
        let request = try GroupUrlRequest.detail(groupID: 42).asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/groups/42")
    }

    @Test func addMemberRequestEncodesNamePayload() throws {
        let request = try GroupUrlRequest.addMember(groupID: 7, name: "Taylor Brooks").asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/groups/7/members")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["name"] == "Taylor Brooks")
    }

    @Test func addUserProfileRequestEncodesUserIDPayload() throws {
        let request = try GroupUrlRequest.addUserProfile(groupID: 9, userID: "firebase-uid-101").asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/groups/9/members")
        #expect(json["userID"] == "firebase-uid-101")
    }

    @Test func deleteMemberRequestUsesDeleteMethod() throws {
        let request = try GroupUrlRequest.deleteMember(groupID: 9, memberID: 101).asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/groups/9/members/101")
        #expect(request.httpBody == nil)
    }
}
