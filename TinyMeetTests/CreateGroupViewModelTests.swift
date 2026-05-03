import Foundation
import Testing
@testable import TinyMeet

struct CreateGroupViewModelTests {
    struct MockProfileRepository: ProfileRespositoryProtocol {
        let fetchFriendsHandler: @Sendable () async throws -> [UserProfile]

        init(fetchFriendsHandler: @escaping @Sendable () async throws -> [UserProfile] = { [] }) {
            self.fetchFriendsHandler = fetchFriendsHandler
        }

        func fetchUserProfile() async throws -> UserProfile { UserProfile.mock }
        func fetchFriendProfiles() async throws -> [UserProfile] { try await fetchFriendsHandler() }
        func fetchFriendRequests() async throws -> [UserProfile] { [] }
        func searchUserProfiles(query: String) async throws -> [UserProfile] { [] }
        func acceptFriendRequest(_ request: UserProfile) async throws {}
        func rejectFriendRequest(_ request: UserProfile) async throws {}
        func addFriend(_ profile: UserProfile) async throws {}
        func removeFriend(_ profile: UserProfile) async throws {}
    }

    struct MockGroupsRepository: GroupsRepositoryProtocol {
        let createGroupHandler: @Sendable (CreateGroupRequest) async throws -> Void

        init(createGroupHandler: @escaping @Sendable (CreateGroupRequest) async throws -> Void = { _ in }) {
            self.createGroupHandler = createGroupHandler
        }

        func fetchGroups() async throws -> [MeetupGroup] { [] }
        func createGroup(_ request: CreateGroupRequest) async throws { try await createGroupHandler(request) }
        func fetchGroupDetail(groupID: String) async throws -> GroupDetail { GroupDetail.mockDetails[0] }
        func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
        func addUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws -> GroupDetail { GroupDetail.mockDetails[0] }
        func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
    }

    actor CreateGroupRequestRecorder {
        private(set) var request: CreateGroupRequest?

        func record(_ request: CreateGroupRequest) {
            self.request = request
        }
    }

    @MainActor
    @Test func createGroupSubmitsTrimmedPayload() async throws {
        let amy = UserProfile(
            id: "friend-amy",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
        let noah = UserProfile(
            id: "friend-noah",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
        let recorder = CreateGroupRequestRecorder()
        let viewModel = CreateGroupViewModel(
            profileRepository: MockProfileRepository(fetchFriendsHandler: { [amy, noah] }),
            groupsRepository: MockGroupsRepository(createGroupHandler: { request in
                await recorder.record(request)
            })
        )

        await viewModel.loadFriends()
        viewModel.groupName = "  Weekend Hikers  "
        viewModel.groupLocation = "  Palo Alto  "
        viewModel.groupSummary = "  Easy weekend hikes.  "
        viewModel.toggleSelection(for: noah)
        viewModel.toggleSelection(for: amy)

        let didSucceed = await viewModel.createGroup()
        let request = await recorder.request

        #expect(didSucceed)
        #expect(request == CreateGroupRequest(
            name: "Weekend Hikers",
            location: "Palo Alto",
            summary: "Easy weekend hikes.",
            friendUIDs: ["friend-amy", "friend-noah"]
        ))
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSubmitting == false)
    }

    @MainActor
    @Test func createGroupStoresRepositoryError() async throws {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Unable to create group" }
        }

        let amy = UserProfile(
            id: "friend-amy",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
        let viewModel = CreateGroupViewModel(
            profileRepository: MockProfileRepository(fetchFriendsHandler: { [amy] }),
            groupsRepository: MockGroupsRepository(createGroupHandler: { _ in
                throw SampleError()
            })
        )

        await viewModel.loadFriends()
        viewModel.groupName = "Weekend Hikers"
        viewModel.toggleSelection(for: amy)

        let didSucceed = await viewModel.createGroup()

        #expect(didSucceed == false)
        #expect(viewModel.errorMessage == "Unable to create group")
        #expect(viewModel.isSubmitting == false)
    }
}
