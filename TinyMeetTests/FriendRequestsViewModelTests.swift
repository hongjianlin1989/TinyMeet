import Foundation
import Testing
@testable import TinyMeet

struct FriendRequestsViewModelTests {
    struct MockFriendsRepository: FriendsRepositoryProtocol {
        let fetchFriendRequestsHandler: @Sendable () async throws -> [UserProfile]
        let acceptFriendRequestHandler: @Sendable (UserProfile) async throws -> Void
        let rejectFriendRequestHandler: @Sendable (UserProfile) async throws -> Void

        init(
            fetchFriendRequestsHandler: @escaping @Sendable () async throws -> [UserProfile],
            acceptFriendRequestHandler: @escaping @Sendable (UserProfile) async throws -> Void = { _ in },
            rejectFriendRequestHandler: @escaping @Sendable (UserProfile) async throws -> Void = { _ in }
        ) {
            self.fetchFriendRequestsHandler = fetchFriendRequestsHandler
            self.acceptFriendRequestHandler = acceptFriendRequestHandler
            self.rejectFriendRequestHandler = rejectFriendRequestHandler
        }

        func fetchFriendProfiles() async throws -> [UserProfile] { [] }
        func fetchFriendRequests() async throws -> [UserProfile] { try await fetchFriendRequestsHandler() }
        func acceptFriendRequest(_ request: UserProfile) async throws { try await acceptFriendRequestHandler(request) }
        func rejectFriendRequest(_ request: UserProfile) async throws { try await rejectFriendRequestHandler(request) }
        func addFriend(_ profile: UserProfile) async throws { }
        func removeFriend(_ profile: UserProfile) async throws { }
    }

    struct MockGroupsRepository: GroupsRepositoryProtocol {
        let fetchGroupInvitesHandler: @Sendable () async throws -> [GroupInvite]
        let acceptGroupInviteHandler: @Sendable (GroupInvite) async throws -> Void
        let rejectGroupInviteHandler: @Sendable (GroupInvite) async throws -> Void

        init(
            fetchGroupInvitesHandler: @escaping @Sendable () async throws -> [GroupInvite] = { [] },
            acceptGroupInviteHandler: @escaping @Sendable (GroupInvite) async throws -> Void = { _ in },
            rejectGroupInviteHandler: @escaping @Sendable (GroupInvite) async throws -> Void = { _ in }
        ) {
            self.fetchGroupInvitesHandler = fetchGroupInvitesHandler
            self.acceptGroupInviteHandler = acceptGroupInviteHandler
            self.rejectGroupInviteHandler = rejectGroupInviteHandler
        }

        func fetchGroups() async throws -> [MeetupGroup] { [] }
        func fetchGroupInvites() async throws -> [GroupInvite] { try await fetchGroupInvitesHandler() }
        func acceptGroupInvite(_ invite: GroupInvite) async throws { try await acceptGroupInviteHandler(invite) }
        func rejectGroupInvite(_ invite: GroupInvite) async throws { try await rejectGroupInviteHandler(invite) }
        func createGroup(_ request: CreateGroupRequest) async throws { }
        func fetchGroupDetail(groupID: String) async throws -> GroupDetail { GroupDetail.mockDetails[0] }
        func deleteGroup(groupID: String) async throws { }
        func leaveGroup(groupID: String) async throws -> Bool { true }
        func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail { groupDetail }
        func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws { }
        func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool { true }
    }

    @MainActor
    @Test func loadRequestsPopulatesFriendAndGroupRequests() async throws {
        let amy = UserProfile(
            id: "request-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let noah = UserProfile(
            id: "request-noahpatel",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: "Mobile engineer",
            age: 29,
            avatarURL: nil
        )
        let invite = GroupInvite(
            id: "group-invite-1",
            groupID: "group-101",
            groupName: "Coffee Chat Crew",
            groupSummary: "Weekly casual meetups.",
            ownerUID: "owner-1",
            createdAt: nil
        )

        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(fetchFriendRequestsHandler: { [amy, noah] }),
            groupsRepository: MockGroupsRepository(fetchGroupInvitesHandler: { [invite] })
        )

        await viewModel.loadRequests()

        #expect(viewModel.requests.count == 3)
        #expect(viewModel.requests[0] == .friend(amy))
        #expect(viewModel.requests[1] == .friend(noah))
        #expect(viewModel.requests[2] == .group(invite))
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func loadRequestsPreservesFriendRequestsWhenGroupInvitesFail() async throws {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Failed to load group invites" }
        }

        let amy = UserProfile(
            id: "request-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )

        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(fetchFriendRequestsHandler: { [amy] }),
            groupsRepository: MockGroupsRepository(fetchGroupInvitesHandler: { throw SampleError() })
        )

        await viewModel.loadRequests()

        #expect(viewModel.requests == [.friend(amy)])
        #expect(viewModel.errorMessage == "Failed to load group invites")
    }

    @MainActor
    @Test func acceptRemovesHandledRequestAndStoresSuccessMessage() async throws {
        let amy = UserProfile(
            id: "request-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(
                fetchFriendRequestsHandler: { [amy] },
                acceptFriendRequestHandler: { request in
                    #expect(request.id == amy.id)
                }
            ),
            groupsRepository: MockGroupsRepository()
        )

        await viewModel.loadRequests()
        let request = try #require(viewModel.requests.first)
        await viewModel.accept(request)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Accepted @amychen's request.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }

    @MainActor
    @Test func rejectRemovesHandledRequestAndStoresSuccessMessage() async throws {
        let noah = UserProfile(
            id: "request-noahpatel",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: "Mobile engineer",
            age: 29,
            avatarURL: nil
        )
        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(
                fetchFriendRequestsHandler: { [noah] },
                rejectFriendRequestHandler: { request in
                    #expect(request.id == noah.id)
                }
            ),
            groupsRepository: MockGroupsRepository()
        )

        await viewModel.loadRequests()
        let request = try #require(viewModel.requests.first)
        await viewModel.reject(request)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Rejected @noahpatel's request.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }

    @MainActor
    @Test func acceptGroupInviteRemovesHandledInviteAndStoresSuccessMessage() async throws {
        let invite = GroupInvite(
            id: "group-invite-42",
            groupID: "group-42",
            groupName: "Coffee Chat Crew",
            groupSummary: "Weekly casual meetups.",
            ownerUID: "owner-42",
            createdAt: nil
        )

        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(fetchFriendRequestsHandler: { [] }),
            groupsRepository: MockGroupsRepository(
                fetchGroupInvitesHandler: { [invite] },
                acceptGroupInviteHandler: { handledInvite in
                    #expect(handledInvite.id == invite.id)
                }
            )
        )

        await viewModel.loadRequests()
        let request = try #require(viewModel.requests.first)
        await viewModel.accept(request)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Accepted invite to Coffee Chat Crew.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }

    @MainActor
    @Test func rejectGroupInviteRemovesHandledInviteAndStoresSuccessMessage() async throws {
        let invite = GroupInvite(
            id: "group-invite-43",
            groupID: "group-43",
            groupName: "South Bay Builders",
            groupSummary: "Weekend maker meetups.",
            ownerUID: "owner-43",
            createdAt: nil
        )

        let viewModel = FriendRequestsViewModel(
            friendsRepository: MockFriendsRepository(fetchFriendRequestsHandler: { [] }),
            groupsRepository: MockGroupsRepository(
                fetchGroupInvitesHandler: { [invite] },
                rejectGroupInviteHandler: { handledInvite in
                    #expect(handledInvite.id == invite.id)
                }
            )
        )

        await viewModel.loadRequests()
        let request = try #require(viewModel.requests.first)
        await viewModel.reject(request)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Rejected invite to South Bay Builders.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }
}
