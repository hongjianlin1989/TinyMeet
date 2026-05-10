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
    private var isAuthenticated: Bool

    init(
        profileRespository: ProfileRespositoryProtocol,
        friendsRepository: FriendsRepositoryProtocol,
        isAuthenticated: Bool = false
    ) {
        self.profileRespository = profileRespository
        self.friendsRepository = friendsRepository
        self.isAuthenticated = isAuthenticated
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

    func onAppear(isLoggedIn: Bool) {
        setAuthenticationState(isLoggedIn, resetWhenSignedOut: true)
    }

    func authenticationStateChanged(isLoggedIn: Bool) {
        setAuthenticationState(isLoggedIn, resetWhenSignedOut: false)
    }

    func searchProfiles() async {
        guard isAuthenticated else {
            resetSignedOutState()
            return
        }

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
        guard isAuthenticated else {
            resetSignedOutState()
            return
        }

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

    func resetSignedOutState() {
        searchText = ""
        profiles = []
        addedFriendIDs = []
        isLoading = false
        errorMessage = nil
        successMessage = nil
    }
}

private extension DiscoverViewModel {
    func setAuthenticationState(_ isLoggedIn: Bool, resetWhenSignedOut: Bool) {
        let didChangeAuthenticationState = isAuthenticated != isLoggedIn
        isAuthenticated = isLoggedIn

        guard didChangeAuthenticationState || resetWhenSignedOut else { return }

        if isLoggedIn == false {
            resetSignedOutState()
        }
    }
}
