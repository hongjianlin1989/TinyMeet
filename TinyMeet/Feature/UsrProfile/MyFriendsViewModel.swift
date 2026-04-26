import Combine
import Foundation

@MainActor
final class MyFriendsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

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
            friend.username.localizedLowercase.contains(normalizedQuery)
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
}
