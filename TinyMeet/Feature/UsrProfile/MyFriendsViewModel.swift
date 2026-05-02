import Combine
import Foundation

@MainActor
final class MyFriendsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var removingFriendIDs: Set<String> = []

    private let profileRepository: ProfileRespositoryProtocol

    init(profileRepository: ProfileRespositoryProtocol) {
        self.profileRepository = profileRepository
    }

    static func makeDefault() -> MyFriendsViewModel {
        MyFriendsViewModel(profileRepository: ProfileRespository())
    }

    var filteredFriends: [UserProfile] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return friends
        }

        let normalizedQuery = trimmedQuery.localizedLowercase
        return friends.filter { friend in
            friend.displayName.localizedLowercase.contains(normalizedQuery)
                || friend.username.localizedLowercase.contains(normalizedQuery)
                || (friend.bio?.localizedLowercase.contains(normalizedQuery) ?? false)
        }
    }

    func loadFriends() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            friends = try await profileRepository.fetchFriendProfiles()
        } catch {
            friends = []
            errorMessage = error.localizedDescription
        }
    }

    func isRemoving(_ friend: UserProfile) -> Bool {
        removingFriendIDs.contains(friend.id)
    }

    func removeFriend(_ friend: UserProfile) async {
        guard !removingFriendIDs.contains(friend.id) else { return }

        removingFriendIDs.insert(friend.id)
        errorMessage = nil
        defer { removingFriendIDs.remove(friend.id) }

        do {
            try await profileRepository.removeFriend(friend)
            friends.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
