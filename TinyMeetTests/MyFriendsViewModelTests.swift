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
        func fetchFriendRequests() async throws -> [UserProfile] { [] }
        func searchUserProfiles(query: String) async throws -> [UserProfile] { [] }
        func acceptFriendRequest(_ request: UserProfile) async throws {}
        func rejectFriendRequest(_ request: UserProfile) async throws {}
        func addFriend(_ profile: UserProfile) async throws {}
        func removeFriend(_ profile: UserProfile) async throws { try await removeFriendHandler(profile) }
    }

    @MainActor
    @Test func loadFriendsAndFilterResults() async throws {
        let amy = UserProfile(
            id: "friend-amychen",
            username: "friend-amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let sofia = UserProfile(
            id: "friend-sofiawang",
            username: "friend-sofiawang",
            displayName: "Sofia Wang",
            email: nil,
            bio: "UX designer who loves coffee chats",
            age: 25,
            avatarURL: nil
        )
        let viewModel = MyFriendsViewModel(
            profileRepository: MockProfileRepository(fetchFriends: { [amy, sofia] })
        )

        await viewModel.loadFriends()

        #expect(viewModel.friends.isEmpty == false)
        #expect(viewModel.friends.contains(where: { $0.displayName == "Amy Chen" }))

        viewModel.searchText = "coffee"
        #expect(viewModel.filteredFriends.contains(where: { $0.displayName == "Amy Chen" }))
        #expect(viewModel.filteredFriends.contains(where: { $0.displayName == "Sofia Wang" }))

        viewModel.searchText = "amy chen"
        #expect(viewModel.filteredFriends.count == 1)
        #expect(viewModel.filteredFriends.first?.displayName == "Amy Chen")

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
