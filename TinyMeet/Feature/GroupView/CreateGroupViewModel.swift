import Combine
import Foundation

@MainActor
final class CreateGroupViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var selectedFriendIDs: Set<Int> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let profileRepository: ProfileRespositoryProtocol

    init(profileRepository: ProfileRespositoryProtocol) {
        self.profileRepository = profileRepository
    }

    static func makeDefault() -> CreateGroupViewModel {
        CreateGroupViewModel(profileRepository: ProfileRespository())
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

    var selectedCountText: String {
        let count = selectedFriendIDs.count
        return count == 1 ? "1 friend selected" : "\(count) friends selected"
    }

    var canCreateGroup: Bool {
        !selectedFriendIDs.isEmpty
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

    func toggleSelection(for friend: UserProfile) {
        if selectedFriendIDs.contains(friend.id) {
            selectedFriendIDs.remove(friend.id)
        } else {
            selectedFriendIDs.insert(friend.id)
        }
    }

    func isSelected(_ friend: UserProfile) -> Bool {
        selectedFriendIDs.contains(friend.id)
    }

    func createGroup() {
        guard canCreateGroup else { return }
        // Group creation flow will be implemented here.
    }
}
