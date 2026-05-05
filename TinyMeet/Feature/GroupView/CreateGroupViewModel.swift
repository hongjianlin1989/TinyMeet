import Combine
import Foundation

@MainActor
final class CreateGroupViewModel: ObservableObject {
    @Published var groupName = ""
    @Published var groupLocation = ""
    @Published var groupSummary = ""
    @Published var searchText = ""
    @Published private(set) var friends: [UserProfile] = []
    @Published private(set) var selectedFriendIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    private let friendsRepository: FriendsRepositoryProtocol
    private let groupsRepository: GroupsRepositoryProtocol

    init(
        friendsRepository: FriendsRepositoryProtocol,
        groupsRepository: GroupsRepositoryProtocol
    ) {
        self.friendsRepository = friendsRepository
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> CreateGroupViewModel {
        CreateGroupViewModel(
            friendsRepository: FriendsRepository(),
            groupsRepository: GroupsRepository()
        )
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

    var selectedCountText: String {
        let count = selectedFriendIDs.count
        return count == 1 ? "1 friend selected" : "\(count) friends selected"
    }

    var canCreateGroup: Bool {
        !isSubmitting
            && !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedFriendIDs.isEmpty
    }

    func loadFriends() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            friends = try await friendsRepository.fetchFriendProfiles()
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

    func createGroup() async -> Bool {
        guard canCreateGroup else { return false }

        isSubmitting = true
        errorMessage = nil

        defer { isSubmitting = false }

        do {
            try await groupsRepository.createGroup(
                CreateGroupRequest(
                    name: groupName.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: groupLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                    summary: groupSummary.trimmingCharacters(in: .whitespacesAndNewlines),
                    friendUIDs: selectedFriendIDs.sorted()
                )
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
