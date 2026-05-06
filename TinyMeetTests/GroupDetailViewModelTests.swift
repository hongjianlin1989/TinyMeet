import Foundation
import Testing
@testable import TinyMeet

struct GroupDetailViewModelTests {
    struct MockGroupsRepository: GroupsRepositoryProtocol {
        let fetchGroupDetailHandler: @Sendable (String) async throws -> GroupDetail
        let inviteUserProfileHandler: @Sendable (UserProfile, String) async throws -> Void
        let deleteMemberHandler: @Sendable (String, GroupDetail) async throws -> Bool
        let deleteGroupHandler: @Sendable (String) async throws -> Void

        init(
            fetchGroupDetailHandler: @escaping @Sendable (String) async throws -> GroupDetail,
            inviteUserProfileHandler: @escaping @Sendable (UserProfile, String) async throws -> Void = { _, _ in },
            deleteMemberHandler: @escaping @Sendable (String, GroupDetail) async throws -> Bool = { _, _ in true },
            deleteGroupHandler: @escaping @Sendable (String) async throws -> Void = { _ in }
        ) {
            self.fetchGroupDetailHandler = fetchGroupDetailHandler
            self.inviteUserProfileHandler = inviteUserProfileHandler
            self.deleteMemberHandler = deleteMemberHandler
            self.deleteGroupHandler = deleteGroupHandler
        }

        func fetchGroups() async throws -> [MeetupGroup] { [] }
        func fetchGroupInvites() async throws -> [GroupInvite] { [] }
        func acceptGroupInvite(_ invite: GroupInvite) async throws { }
        func rejectGroupInvite(_ invite: GroupInvite) async throws { }
        func createGroup(_ request: CreateGroupRequest) async throws { }
        func fetchGroupDetail(groupID: String) async throws -> GroupDetail {
            try await fetchGroupDetailHandler(groupID)
        }
        func deleteGroup(groupID: String) async throws {
            try await deleteGroupHandler(groupID)
        }
        func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
        func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws {
            try await inviteUserProfileHandler(userProfile, groupID)
        }
        func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool {
            try await deleteMemberHandler(memberID, groupDetail)
        }
    }

    struct MockProfileRepository: ProfileRespositoryProtocol {
        let fetchUserProfileHandler: @Sendable () async throws -> UserProfile

        init(fetchUserProfileHandler: @escaping @Sendable () async throws -> UserProfile = { UserProfile.mock }) {
            self.fetchUserProfileHandler = fetchUserProfileHandler
        }

        func fetchUserProfile() async throws -> UserProfile {
            try await fetchUserProfileHandler()
        }

        func searchUserProfiles(query: String) async throws -> [UserProfile] { [] }
    }

    struct MockFriendsRepository: FriendsRepositoryProtocol {
        let fetchFriendProfilesHandler: @Sendable () async throws -> [UserProfile]

        init(fetchFriendProfilesHandler: @escaping @Sendable () async throws -> [UserProfile] = { [] }) {
            self.fetchFriendProfilesHandler = fetchFriendProfilesHandler
        }

        func fetchFriendProfiles() async throws -> [UserProfile] {
            try await fetchFriendProfilesHandler()
        }

        func fetchFriendRequests() async throws -> [UserProfile] { [] }
        func acceptFriendRequest(_ request: UserProfile) async throws { }
        func rejectFriendRequest(_ request: UserProfile) async throws { }
        func addFriend(_ profile: UserProfile) async throws { }
        func removeFriend(_ profile: UserProfile) async throws { }
    }

    actor DeleteGroupRecorder {
        private(set) var deletedGroupIDs: [String] = []

        func record(groupID: String) {
            deletedGroupIDs.append(groupID)
        }
    }

    actor InvitedFriendRecorder {
        private(set) var entries: [(userID: String, groupID: String)] = []

        func record(userID: String, groupID: String) {
            entries.append((userID: userID, groupID: groupID))
        }
    }

    actor DeletedMemberRecorder {
        private(set) var entries: [(memberID: String, groupID: String)] = []

        func record(memberID: String, groupID: String) {
            entries.append((memberID: memberID, groupID: groupID))
        }
    }

    @MainActor
    @Test func canDeleteGroupIsTrueWhenOwnerIDMatchesCurrentUserProfileID() async throws {
        let detail = GroupDetail(
            id: "group-123",
            name: "Weekend Hikers",
            location: "Palo Alto",
            summary: "Easy weekend hikes.",
            ownerUID: "owner-123",
            createdAt: nil,
            members: []
        )
        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(fetchGroupDetailHandler: { _ in detail }),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(
                    id: "owner-123",
                    username: "amychen",
                    displayName: "Amy Chen",
                    email: nil,
                    bio: nil,
                    age: nil,
                    avatarURL: nil
                )
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()

        #expect(viewModel.groupDetail == detail)
        #expect(viewModel.canDeleteGroup)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func deleteGroupCallsRepositoryAndClearsDetailOnSuccess() async throws {
        let detail = GroupDetail(
            id: "group-456",
            name: "SwiftUI Builders",
            location: "San Jose",
            summary: "Ship side projects.",
            ownerUID: "owner-456",
            createdAt: nil,
            members: [GroupMember(id: "member-1", name: "Taylor", role: "member", joinedAt: nil)]
        )
        let recorder = DeleteGroupRecorder()
        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(
                fetchGroupDetailHandler: { _ in detail },
                deleteGroupHandler: { groupID in
                    await recorder.record(groupID: groupID)
                }
            ),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(
                    id: "owner-456",
                    username: "miapark",
                    displayName: "Mia Park",
                    email: nil,
                    bio: nil,
                    age: nil,
                    avatarURL: nil
                )
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()
        let didDelete = await viewModel.deleteGroup()

        #expect(didDelete)
        #expect(await recorder.deletedGroupIDs == ["group-456"])
        #expect(viewModel.groupDetail == nil)
        #expect(viewModel.friends.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test func deleteGroupFailsForNonOwnerWithoutCallingRepository() async throws {
        let detail = GroupDetail(
            id: "group-789",
            name: "Coffee Chat Crew",
            location: "Cupertino",
            summary: "Weekly meetups.",
            ownerUID: "owner-789",
            createdAt: nil,
            members: []
        )
        let recorder = DeleteGroupRecorder()
        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(
                fetchGroupDetailHandler: { _ in detail },
                deleteGroupHandler: { groupID in
                    await recorder.record(groupID: groupID)
                }
            ),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(
                    id: "someone-else",
                    username: "noahpatel",
                    displayName: "Noah Patel",
                    email: nil,
                    bio: nil,
                    age: nil,
                    avatarURL: nil
                )
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()
        let didDelete = await viewModel.deleteGroup()

        #expect(didDelete == false)
        #expect(viewModel.canDeleteGroup == false)
        #expect(await recorder.deletedGroupIDs.isEmpty)
        #expect(viewModel.groupDetail == detail)
        #expect(viewModel.errorMessage == "Only the group owner can delete this group.")
    }

    @MainActor
    @Test func fetchGroupDetailStillLoadsGroupWhenCurrentUserProfileLookupFails() async throws {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Profile unavailable" }
        }

        let detail = GroupDetail(
            id: "group-111",
            name: "Parents & Play",
            location: "Mountain View",
            summary: "Neighborhood meetups.",
            ownerUID: "owner-111",
            createdAt: nil,
            members: []
        )

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(fetchGroupDetailHandler: { _ in detail }),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                throw SampleError()
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()

        #expect(viewModel.groupDetail == detail)
        #expect(viewModel.canDeleteGroup == false)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func loadFriendsLoadsFriendsForOwnerAndFiltersExistingMembers() async throws {
        let detail = GroupDetail(
            id: "group-222",
            name: "Playdate Crew",
            location: "Sunnyvale",
            summary: "Weekend fun.",
            ownerUID: "owner-222",
            createdAt: nil,
            members: [
                GroupMember(id: "friend-amy", name: "amychen", role: "member", joinedAt: nil)
            ]
        )
        let amy = UserProfile(id: "friend-amy", username: "amychen", displayName: "Amy Chen", email: nil, bio: nil, age: nil, avatarURL: nil)
        let noah = UserProfile(id: "friend-noah", username: "noahpatel", displayName: "Noah Patel", email: nil, bio: nil, age: nil, avatarURL: nil)

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(fetchGroupDetailHandler: { _ in detail }),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(id: "owner-222", username: "owner", displayName: "Owner", email: nil, bio: nil, age: nil, avatarURL: nil)
            }),
            friendsRepository: MockFriendsRepository(fetchFriendProfilesHandler: { [amy, noah] })
        )

        await viewModel.fetchGroupDetail()
        await viewModel.loadFriends()

        #expect(viewModel.canManageMembers)
        #expect(viewModel.friends == [amy, noah])
        #expect(viewModel.availableFriendsToAdd == [noah])
    }

    @MainActor
    @Test func loadFriendsDoesNothingForNonOwner() async throws {
        let detail = GroupDetail(
            id: "group-333",
            name: "Coffee Chat Crew",
            location: "Cupertino",
            summary: "Weekly meetups.",
            ownerUID: "owner-333",
            createdAt: nil,
            members: []
        )

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(fetchGroupDetailHandler: { _ in detail }),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(id: "someone-else", username: "guest", displayName: "Guest", email: nil, bio: nil, age: nil, avatarURL: nil)
            }),
            friendsRepository: MockFriendsRepository(fetchFriendProfilesHandler: {
                Issue.record("Friends should not be loaded for non-owners")
                return []
            })
        )

        await viewModel.fetchGroupDetail()
        await viewModel.loadFriends()

        #expect(viewModel.canManageMembers == false)
        #expect(viewModel.friends.isEmpty)
    }

    @MainActor
    @Test func addFriendToGroupUsesSelectedFriendProfile() async throws {
        let detail = GroupDetail(
            id: "group-444",
            name: "SwiftUI Builders",
            location: "San Jose",
            summary: "Ship side projects.",
            ownerUID: "owner-444",
            createdAt: nil,
            members: []
        )
        let noah = UserProfile(id: "friend-noah", username: "noahpatel", displayName: "Noah Patel", email: nil, bio: nil, age: nil, avatarURL: nil)
        let recorder = InvitedFriendRecorder()

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(
                fetchGroupDetailHandler: { _ in detail },
                inviteUserProfileHandler: { userProfile, groupID in
                    await recorder.record(userID: userProfile.id, groupID: groupID)
                }
            ),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(id: "owner-444", username: "owner", displayName: "Owner", email: nil, bio: nil, age: nil, avatarURL: nil)
            }),
            friendsRepository: MockFriendsRepository(fetchFriendProfilesHandler: { [noah] })
        )

        await viewModel.fetchGroupDetail()
        await viewModel.loadFriends()
        await viewModel.addFriendToGroup(noah)

        #expect(await recorder.entries.count == 1)
        #expect(await recorder.entries.first?.userID == "friend-noah")
        #expect(await recorder.entries.first?.groupID == "group-444")
        #expect(viewModel.groupDetail == detail)
        #expect(viewModel.availableFriendsToAdd.isEmpty)
        #expect(viewModel.errorMessage == "Invitation sent to Noah Patel.")
    }

    @MainActor
    @Test func deleteMemberUsesRepositoryForOwner() async throws {
        let detail = GroupDetail(
            id: "group-555",
            name: "Playdate Crew",
            location: "Sunnyvale",
            summary: "Weekend fun.",
            ownerUID: "owner-555",
            createdAt: nil,
            members: [
                GroupMember(id: "member-1", name: "Taylor", role: "member", joinedAt: nil),
                GroupMember(id: "member-2", name: "Alex", role: "member", joinedAt: nil)
            ]
        )
        let recorder = DeletedMemberRecorder()

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(
                fetchGroupDetailHandler: { _ in detail },
                deleteMemberHandler: { memberID, groupDetail in
                    await recorder.record(memberID: memberID, groupID: groupDetail.id)
                    return true
                }
            ),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(id: "owner-555", username: "owner", displayName: "Owner", email: nil, bio: nil, age: nil, avatarURL: nil)
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()
        await viewModel.deleteMember(memberID: "member-1")

        #expect(await recorder.entries.count == 1)
        #expect(await recorder.entries.first?.memberID == "member-1")
        #expect(await recorder.entries.first?.groupID == "group-555")
        #expect(viewModel.groupDetail?.members == [
            GroupMember(id: "member-2", name: "Alex", role: "member", joinedAt: nil)
        ])
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func deleteMemberDoesNothingForNonOwner() async throws {
        let detail = GroupDetail(
            id: "group-666",
            name: "Coffee Chat Crew",
            location: "Cupertino",
            summary: "Weekly meetups.",
            ownerUID: "owner-666",
            createdAt: nil,
            members: [
                GroupMember(id: "member-1", name: "Taylor", role: "member", joinedAt: nil)
            ]
        )
        let recorder = DeletedMemberRecorder()

        let viewModel = GroupDetailViewModel(
            groupID: detail.id,
            groupsRepository: MockGroupsRepository(
                fetchGroupDetailHandler: { _ in detail },
                deleteMemberHandler: { memberID, groupDetail in
                    await recorder.record(memberID: memberID, groupID: groupDetail.id)
                    return true
                }
            ),
            profileRepository: MockProfileRepository(fetchUserProfileHandler: {
                UserProfile(id: "someone-else", username: "guest", displayName: "Guest", email: nil, bio: nil, age: nil, avatarURL: nil)
            }),
            friendsRepository: MockFriendsRepository()
        )

        await viewModel.fetchGroupDetail()
        await viewModel.deleteMember(memberID: "member-1")

        #expect(await recorder.entries.isEmpty)
        #expect(viewModel.groupDetail == detail)
        #expect(viewModel.errorMessage == "Only the group owner can remove members.")
    }
}
