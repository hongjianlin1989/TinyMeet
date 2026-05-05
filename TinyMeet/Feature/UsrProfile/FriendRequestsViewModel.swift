import Combine
import Foundation

@MainActor
final class FriendRequestsViewModel: ObservableObject {
    @Published private(set) var requests: [UserProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var respondingRequestIDs: Set<String> = []

    private let friendsRepository: FriendsRepositoryProtocol

    init(friendsRepository: FriendsRepositoryProtocol) {
        self.friendsRepository = friendsRepository
    }

    static func makeDefault() -> FriendRequestsViewModel {
        FriendRequestsViewModel(friendsRepository: FriendsRepository())
    }

    func loadRequests() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        do {
            requests = try await friendsRepository.fetchFriendRequests()
        } catch {
            requests = []
            errorMessage = error.localizedDescription
        }
    }

    func isResponding(_ request: UserProfile) -> Bool {
        respondingRequestIDs.contains(request.id)
    }

    func accept(_ request: UserProfile) async {
        await respond(to: request, action: .accept)
    }

    func reject(_ request: UserProfile) async {
        await respond(to: request, action: .reject)
    }

    private func respond(to request: UserProfile, action: FriendRequestResponseAction) async {
        guard !respondingRequestIDs.contains(request.id) else { return }

        respondingRequestIDs.insert(request.id)
        errorMessage = nil
        successMessage = nil

        defer { respondingRequestIDs.remove(request.id) }

        do {
            switch action {
            case .accept:
                try await friendsRepository.acceptFriendRequest(request)
                successMessage = "Accepted @\(request.username)'s request."
            case .reject:
                try await friendsRepository.rejectFriendRequest(request)
                successMessage = "Rejected @\(request.username)'s request."
            }

            requests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
