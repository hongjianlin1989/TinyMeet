import Combine
import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var profiles: [UserProfile] = []
    @Published private(set) var addedFriendIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let profileRespository: ProfileRespositoryProtocol
    private let friendsRepository: FriendsRepositoryProtocol

    init(
        profileRespository: ProfileRespositoryProtocol,
        friendsRepository: FriendsRepositoryProtocol
    ) {
        self.profileRespository = profileRespository
        self.friendsRepository = friendsRepository
    }

    static func makeDefault() -> DiscoverViewModel {
        DiscoverViewModel(
            profileRespository: ProfileRespository(),
            friendsRepository: FriendsRepository()
        )
    }

    var hasActiveQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func hasAddedFriend(_ profile: UserProfile) -> Bool {
        addedFriendIDs.contains(profile.id)
    }

    func searchProfiles() async {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            profiles = []
            errorMessage = nil
            successMessage = nil
            return
        }

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        do {
            profiles = try await profileRespository.searchUserProfiles(query: trimmedQuery)
        } catch {
            profiles = []
            errorMessage = error.localizedDescription
        }
    }

    func addFriend(_ profile: UserProfile) async {
        guard !isLoading else { return }
        guard addedFriendIDs.contains(profile.id) == false else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        do {
            try await friendsRepository.addFriend(profile)
            addedFriendIDs.insert(profile.id)
            successMessage = "Added @\(profile.username) as a friend."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
