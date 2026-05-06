import Combine
import Foundation

@MainActor
final class GroupDetailViewModel: ObservableObject {
    @Published private(set) var groupDetail: GroupDetail?
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let groupID: String
    private let groupsRepository: GroupsRepositoryProtocol
    private let profileRepository: ProfileRespositoryProtocol
    private let friendsRepository: FriendsRepositoryProtocol
    private var currentUserProfileID: String?
    private var invitedFriendIDs: Set<String> = []

    init(
        groupID: String,
        groupsRepository: GroupsRepositoryProtocol,
        profileRepository: ProfileRespositoryProtocol,
        friendsRepository: FriendsRepositoryProtocol
    ) {
        self.groupID = groupID
        self.groupsRepository = groupsRepository
        self.profileRepository = profileRepository
        self.friendsRepository = friendsRepository
    }

    static func makeDefault(groupID: String) -> GroupDetailViewModel {
        GroupDetailViewModel(
            groupID: groupID,
            groupsRepository: GroupsRepository(),
            profileRepository: ProfileRespository(),
            friendsRepository: FriendsRepository()
        )
    }

    var canManageMembers: Bool {
        canDeleteGroup
    }

    var canDeleteGroup: Bool {
        guard
            let ownerUID = groupDetail?.ownerUID,
            let currentUserProfileID
        else {
            return false
        }

        return ownerUID.caseInsensitiveCompare(currentUserProfileID) == .orderedSame
    }

    var canLeaveGroup: Bool {
        guard canDeleteGroup == false, let groupDetail, let currentUserProfileID else {
            return false
        }

        return groupDetail.members.contains {
            $0.id.caseInsensitiveCompare(currentUserProfileID) == .orderedSame
        }
    }

    var availableFriendsToAdd: [UserProfile] {
        guard let groupDetail else {
            return []
        }

        return friends.filter { friend in
            invitedFriendIDs.contains(where: { $0.caseInsensitiveCompare(friend.id) == .orderedSame }) == false
                &&
            groupDetail.members.contains(where: {
                $0.id.caseInsensitiveCompare(friend.id) == .orderedSame
                    || $0.name.caseInsensitiveCompare(friend.username) == .orderedSame
            }) == false
        }
    }

    func fetchGroupDetail() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentUserProfileID = nil
        friends = []
        invitedFriendIDs.removeAll()

        defer { isLoading = false }

        do {
            async let fetchedGroupDetail = groupsRepository.fetchGroupDetail(groupID: groupID)
            async let fetchedUserProfile = profileRepository.fetchUserProfile()

            groupDetail = try await fetchedGroupDetail
            currentUserProfileID = try? await fetchedUserProfile.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadFriends() async {
        guard !isLoading else { return }
        guard canManageMembers else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            friends = try await friendsRepository.fetchFriendProfiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addFriendToGroup(_ friend: UserProfile) async {
        guard !isLoading, let groupDetail else { return }
        guard canManageMembers else {
            errorMessage = "Only the group owner can add members."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await groupsRepository.inviteUserProfile(friend, toGroupID: groupDetail.id)
            invitedFriendIDs.insert(friend.id)
            errorMessage = "Invitation sent to \(friend.displayName)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMember(memberID: String) async {
        guard !isLoading, let groupDetail else { return }
        guard canManageMembers else {
            errorMessage = "Only the group owner can remove members."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let success = try await groupsRepository.deleteMember(memberID: memberID, from: groupDetail)

            if success {
                self.groupDetail = GroupDetail(
                    id: groupDetail.id,
                    name: groupDetail.name,
                    location: groupDetail.location,
                    summary: groupDetail.summary,
                    ownerUID: groupDetail.ownerUID,
                    createdAt: groupDetail.createdAt,
                    members: groupDetail.members.filter {
                        $0.id.caseInsensitiveCompare(memberID) != .orderedSame
                    }
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteGroup() async -> Bool {
        guard !isLoading, let groupDetail else { return false }
        guard canDeleteGroup else {
            errorMessage = "Only the group owner can delete this group."
            return false
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await groupsRepository.deleteGroup(groupID: groupDetail.id)
            self.groupDetail = nil
            friends = []
            invitedFriendIDs.removeAll()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func leaveGroup() async -> Bool {
        guard !isLoading, let groupDetail else { return false }
        guard canLeaveGroup else {
            errorMessage = "Only group members can leave this group."
            return false
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let success = try await groupsRepository.leaveGroup(groupID: groupDetail.id)

            if success {
                self.groupDetail = nil
                friends = []
                invitedFriendIDs.removeAll()
            }

            return success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

}
