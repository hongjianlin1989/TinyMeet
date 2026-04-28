import Testing
@testable import TinyMeet

struct MyFriendsViewModelTests {
    struct MockProfileRepository: ProfileRespositoryProtocol {
        let fetchFriends: @Sendable () async throws -> [UserProfile]
        let removeFriendHandler: @Sendable (UserProfile) async throws -> Void

        init(
            fetchFriends: @escaping @Sendable () async throws -> [UserProfile],
            removeFriendHandler: @escaping @Sendable (UserProfile) async throws -> Void = { _ in }
        ) {
            self.fetchFriends = fetchFriends
            self.removeFriendHandler = removeFriendHandler
        }

        func fetchUserProfile() async throws -> UserProfile { UserProfile.mock }
        func fetchFriendProfiles() async throws -> [UserProfile] { try await fetchFriends() }
        func searchUserProfiles(query: String) async throws -> [UserProfile] { [] }
        func addFriend(_ profile: UserProfile) async throws {}
        func removeFriend(_ profile: UserProfile) async throws { try await removeFriendHandler(profile) }
    }

    @MainActor
    @Test func loadFriendsAndFilterResults() async throws {
        let viewModel = MyFriendsViewModel(profileRepository: ProfileRespository())

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty == false)
        #expect(viewModel.friends.contains(where: { $0.username == "amychen" }))

        viewModel.searchText = "coffee"
        #expect(viewModel.filteredFriends.contains(where: { $0.username == "amychen" }))
        #expect(viewModel.filteredFriends.contains(where: { $0.username == "sofiawang" }))

        viewModel.searchText = "no-such-friend"
        #expect(viewModel.filteredFriends.isEmpty)
    }

    @MainActor
    @Test func removeFriendRemovesFriendFromList() async throws {
        let amy = UserProfile(
            id: "user-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let sofia = UserProfile(
            id: "user-sofiawang",
            username: "sofiawang",
            displayName: "Sofia Wang",
            email: nil,
            bio: "UX designer",
            age: 25,
            avatarURL: nil
        )

        let viewModel = MyFriendsViewModel(
            profileRepository: MockProfileRepository(fetchFriends: { [amy, sofia] })
        )

        await viewModel.loadFriends()
        #expect(viewModel.friends.count == 2)

        await viewModel.removeFriend(amy)

        #expect(viewModel.friends.count == 1)
        #expect(viewModel.friends.contains(where: { $0.id == amy.id }) == false)
        #expect(viewModel.friends.first?.id == sofia.id)
    }
}
