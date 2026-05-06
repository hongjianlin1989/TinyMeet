import Foundation
import Testing
@testable import TinyMeet

struct GroupsRepositoryMockJSONTests {
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

    @Test func fetchGroupsDecodesLiveGroupsEnvelope() async throws {
        let payload = """
        {
          "groups": [
            {
              "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
              "name": "South Bay Builders",
              "location": "Sunnyvale",
              "summary": "Weekend maker meetups.",
              "owner_uid": "owner-123",
              "created_at": "2026-05-03T13:23:57.123Z"
            }
          ],
          "next_cursor": "cursor-1"
        }
        """

        let repository = GroupsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let groups = try await repository.fetchGroups()

        #expect(groups.count == 1)
        #expect(groups.first?.id == "3fa85f64-5717-4562-b3fc-2c963f66afa6")
        #expect(groups.first?.name == "South Bay Builders")
        #expect(groups.first?.location == "Sunnyvale")
        #expect(groups.first?.summary == "Weekend maker meetups.")
        #expect(groups.first?.memberCount == 0)
    }

    @Test func fetchGroupDetailDecodesLiveGroupDetailResponse() async throws {
        let payload = """
        {
          "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "name": "South Bay Builders",
          "location": "Sunnyvale",
          "summary": "Weekend maker meetups.",
          "owner_uid": "owner-123",
          "created_at": "2026-05-03T13:31:30.463Z",
          "members": [
            {
              "group_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
              "uid": "member-456",
              "role": "member",
              "joined_at": "2026-05-03T13:31:30.463Z"
            }
          ]
        }
        """

        let repository = GroupsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let detail = try await repository.fetchGroupDetail(groupID: "3fa85f64-5717-4562-b3fc-2c963f66afa6")

        #expect(detail.id == "3fa85f64-5717-4562-b3fc-2c963f66afa6")
        #expect(detail.name == "South Bay Builders")
        #expect(detail.ownerUID == "owner-123")
        #expect(detail.createdAt == "2026-05-03T13:31:30.463Z")
        #expect(detail.members.count == 1)
        let firstMember = try #require(detail.members.first)
        #expect(firstMember.id == "member-456")
        #expect(firstMember.name == "member-456")
        #expect(firstMember.role == "member")
        #expect(firstMember.joinedAt == "2026-05-03T13:31:30.463Z")
    }

    @Test func fetchGroupInvitesDecodesLiveInvitesResponse() async throws {
        let payload = """
        [
          {
            "id": "invite-123",
            "group_id": "group-456",
            "group_name": "South Bay Builders",
            "group_summary": "Weekend maker meetups.",
            "owner_uid": "owner-123",
            "created_at": "2026-05-03T13:31:30.463Z"
          }
        ]
        """

        let repository = GroupsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8)))
        )

        let invites = try await repository.fetchGroupInvites()

        #expect(invites.count == 1)
        #expect(invites.first?.id == "invite-123")
        #expect(invites.first?.groupID == "group-456")
        #expect(invites.first?.groupName == "South Bay Builders")
        #expect(invites.first?.groupSummary == "Weekend maker meetups.")
        #expect(invites.first?.ownerUID == "owner-123")
    }

    @Test func createGroupUsesPostGroupsAPI() async throws {
        let recorder = RequestRecorder()
        let repository = GroupsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{}".data(using: .utf8)),
                recorder: recorder
            )
        )

        try await repository.createGroup(
            CreateGroupRequest(
                name: "Weekend Hikers",
                location: "Palo Alto",
                summary: "Easy weekend hikes.",
                friendUIDs: ["friend-1", "friend-2"]
            )
        )

        let request = await recorder.lastRequest
        let body = try #require(request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let friendUIDs = try #require(json["friend_uids"] as? [String])

        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.path == "/api/v1/groups")
        #expect(json["name"] as? String == "Weekend Hikers")
        #expect(json["location"] as? String == "Palo Alto")
        #expect(json["summary"] as? String == "Easy weekend hikes.")
        #expect(friendUIDs == ["friend-1", "friend-2"])
    }

    @Test func deleteGroupUsesDeleteGroupsAPI() async throws {
        let recorder = RequestRecorder()
        let repository = GroupsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{}".data(using: .utf8)),
                recorder: recorder
            )
        )

        try await repository.deleteGroup(groupID: "group-123")

        let request = await recorder.lastRequest

        #expect(request?.httpMethod == "DELETE")
        #expect(request?.url?.path == "/api/v1/groups/group-123")
        #expect(request?.httpBody == nil)
    }

    @Test func leaveGroupUsesDeleteGroupMembersAPI() async throws {
        let recorder = RequestRecorder()
        let repository = GroupsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{}".data(using: .utf8)),
                recorder: recorder
            )
        )

        let didLeave = try await repository.leaveGroup(groupID: "group-123")

        let request = await recorder.lastRequest

        #expect(didLeave)
        #expect(request?.httpMethod == "DELETE")
        #expect(request?.url?.path == "/api/v1/groups/group-123/members")
        #expect(request?.httpBody == nil)
    }

    @Test func acceptGroupInviteUsesRespondAPI() async throws {
        let recorder = RequestRecorder()
        let repository = GroupsRepository(
            networkManager: RecordingNetworkManager(
                data: try #require("{}".data(using: .utf8)),
                recorder: recorder
            )
        )
        let invite = GroupInvite(
            id: "invite-123",
            groupID: "group-456",
            groupName: "South Bay Builders",
            groupSummary: "Weekend maker meetups.",
            ownerUID: "owner-123",
            createdAt: nil
        )

        try await repository.acceptGroupInvite(invite)

        let request = await recorder.lastRequest
        let body = try #require(request?.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Bool])

        #expect(request?.httpMethod == "POST")
        #expect(request?.url?.path == "/api/v1/groups/invites/invite-123/respond")
        #expect(json["accept"] == true)
    }
}
