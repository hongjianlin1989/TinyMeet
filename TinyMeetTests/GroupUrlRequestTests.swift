import Foundation
import Testing
@testable import TinyMeet

struct GroupUrlRequestTests {
    @Test func listRequestUsesGroupsEndpoint() throws {
        let request = try GroupUrlRequest.list.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/groups")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == ApiConfig.timeoutInterval)
    }

    @Test func createRequestEncodesGroupPayload() throws {
        let request = try GroupUrlRequest.create(
            CreateGroupRequest(
                name: "Weekend Hikers",
                location: "Palo Alto",
                summary: "Easy weekend hikes.",
                friendUIDs: ["friend-1", "friend-2"]
            )
        ).asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let friendUIDs = try #require(json["friend_uids"] as? [String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/groups")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["name"] as? String == "Weekend Hikers")
        #expect(json["location"] as? String == "Palo Alto")
        #expect(json["summary"] as? String == "Easy weekend hikes.")
        #expect(friendUIDs == ["friend-1", "friend-2"])
    }

    @Test func detailRequestUsesGroupDetailEndpoint() throws {
        let request = try GroupUrlRequest.detail(groupID: "group-42").asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/groups/group-42")
    }

    @Test func deleteGroupRequestUsesDeleteMethod() throws {
        let request = try GroupUrlRequest.deleteGroup(groupID: "group-42").asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/api/v1/groups/group-42")
        #expect(request.httpBody == nil)
    }

    @Test func addMemberRequestEncodesNamePayload() throws {
        let request = try GroupUrlRequest.addMember(groupID: "group-7", name: "Taylor Brooks").asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/groups/group-7/members")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["name"] == "Taylor Brooks")
    }

    @Test func inviteUserProfileRequestEncodesInviteeUIDPayload() throws {
        let request = try GroupUrlRequest.inviteUserProfile(groupID: "group-9", inviteeUID: "firebase-uid-101").asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/groups/group-9/invites")
        #expect(json["invitee_uid"] == "firebase-uid-101")
    }

    @Test func deleteMemberRequestUsesDeleteMethod() throws {
        let request = try GroupUrlRequest.deleteMember(groupID: "group-9", memberID: "member-101").asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/api/v1/groups/group-9/members/member-101")
        #expect(request.httpBody == nil)
    }
}
