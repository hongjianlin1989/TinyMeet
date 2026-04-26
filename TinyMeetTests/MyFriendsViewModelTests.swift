import Testing
@testable import TinyMeet

struct MyFriendsViewModelTests {
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
}
