import Combine
import Foundation

@MainActor
final class FriendRequestsViewModel: ObservableObject {
    @Published private(set) var requests: [InviteRequestItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var respondingRequestIDs: Set<String> = []

    private let friendsRepository: FriendsRepositoryProtocol
    private let groupsRepository: GroupsRepositoryProtocol

    init(
        friendsRepository: FriendsRepositoryProtocol,
        groupsRepository: GroupsRepositoryProtocol
    ) {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> FriendRequestsViewModel {
        FriendRequestsViewModel(
            friendsRepository: FriendsRepository(),
            groupsRepository: GroupsRepository()
        )
    }

    func loadRequests() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        async let friendRequestsResult = loadFriendRequests()
        async let groupInvitesResult = loadGroupInvites()

        let (loadedFriendRequests, loadedGroupInvites) = await (friendRequestsResult, groupInvitesResult)

        requests = loadedFriendRequests.items + loadedGroupInvites.items

        let errors = [loadedFriendRequests.errorMessage, loadedGroupInvites.errorMessage]
            .compactMap { $0 }
        if errors.isEmpty == false {
            errorMessage = errors.joined(separator: " ")
        }
    }

    func isResponding(_ request: InviteRequestItem) -> Bool {
        respondingRequestIDs.contains(request.id)
    }

    func accept(_ request: InviteRequestItem) async {
        await respond(to: request, action: .accept)
    }

    func reject(_ request: InviteRequestItem) async {
        await respond(to: request, action: .reject)
    }

    private func loadFriendRequests() async -> InviteLoadResult {
        do {
            let requests = try await friendsRepository.fetchFriendRequests().map(InviteRequestItem.friend)
            return InviteLoadResult(items: requests, errorMessage: nil)
        } catch {
            return InviteLoadResult(items: [], errorMessage: error.localizedDescription)
        }
    }

    private func loadGroupInvites() async -> InviteLoadResult {
        do {
            let requests = try await groupsRepository.fetchGroupInvites().map(InviteRequestItem.group)
            return InviteLoadResult(items: requests, errorMessage: nil)
        } catch {
            return InviteLoadResult(items: [], errorMessage: error.localizedDescription)
        }
    }

    private func respond(to request: InviteRequestItem, action: FriendRequestResponseAction) async {
        guard !respondingRequestIDs.contains(request.id) else { return }

        respondingRequestIDs.insert(request.id)
        errorMessage = nil
        successMessage = nil

        defer { respondingRequestIDs.remove(request.id) }

        do {
            switch request {
            case .friend(let friendRequest):
                switch action {
                case .accept:
                    try await friendsRepository.acceptFriendRequest(friendRequest)
                    successMessage = "Accepted @\(friendRequest.username)'s request."
                case .reject:
                    try await friendsRepository.rejectFriendRequest(friendRequest)
                    successMessage = "Rejected @\(friendRequest.username)'s request."
                }
            case .group(let invite):
                switch action {
                case .accept:
                    try await groupsRepository.acceptGroupInvite(invite)
                    successMessage = "Accepted invite to \(invite.groupName)."
                case .reject:
                    try await groupsRepository.rejectGroupInvite(invite)
                    successMessage = "Rejected invite to \(invite.groupName)."
                }
            }

            requests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct InviteLoadResult {
    let items: [InviteRequestItem]
    let errorMessage: String?
}
