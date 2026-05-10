import Foundation
import Testing
@testable import TinyMeet

struct DiscoverViewModelTests {
    struct MockProfileRepository: ProfileRespositoryProtocol {
        let searchSpy: SearchProfilesSpy?
        let searchResults: [UserProfile]

        func fetchUserProfile() async throws -> UserProfile {
            .mock
        }

        func searchUserProfiles(query: String) async throws -> [UserProfile] {
            if let searchSpy {
                return await searchSpy.search(query: query)
            }

            return searchResults
        }
    }

    struct MockFriendsRepository: FriendsRepositoryProtocol {
        let addFriendSpy: AddFriendSpy?

        func fetchFriendProfiles() async throws -> [UserProfile] {
            []
        }

        func fetchFriendRequests() async throws -> [UserProfile] {
            []
        }

        func acceptFriendRequest(_ request: UserProfile) async throws {}

        func rejectFriendRequest(_ request: UserProfile) async throws {}

        func addFriend(_ profile: UserProfile) async throws {
            if let addFriendSpy {
                await addFriendSpy.recordAdd(profileID: profile.id)
            }
        }

        func removeFriend(_ profile: UserProfile) async throws {}
    }

    actor SearchProfilesSpy {
        private let results: [UserProfile]
        private var queries: [String] = []

        init(results: [UserProfile] = []) {
            self.results = results
        }

        func search(query: String) -> [UserProfile] {
            queries.append(query)
            return results
        }

        func recordedQueries() -> [String] {
            queries
        }
    }

    actor AddFriendSpy {
        private var addedProfileIDs: [String] = []

        func recordAdd(profileID: String) {
            addedProfileIDs.append(profileID)
        }

        func recordedProfileIDs() -> [String] {
            addedProfileIDs
        }
    }

    @MainActor
    @Test func signedOutDiscoverDoesNotCallSearchOrAddFriendRepositories() async throws {
        let profile = UserProfile.mock
        let searchSpy = SearchProfilesSpy(results: [profile])
        let addFriendSpy = AddFriendSpy()
        let viewModel = makeViewModel(
            searchSpy: searchSpy,
            addFriendSpy: addFriendSpy,
            isAuthenticated: false
        )

        viewModel.searchText = "amy"
        await viewModel.searchProfiles()
        await viewModel.addFriend(profile)

        let recordedQueries = await searchSpy.recordedQueries()
        let recordedAdds = await addFriendSpy.recordedProfileIDs()

        #expect(recordedQueries.isEmpty)
        #expect(recordedAdds.isEmpty)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.profiles.isEmpty)
        #expect(viewModel.hasAddedFriend(profile) == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.successMessage == nil)
    }

    @MainActor
    @Test func signingOutClearsDiscoverState() async throws {
        let profile = UserProfile.mock
        let searchSpy = SearchProfilesSpy(results: [profile])
        let addFriendSpy = AddFriendSpy()
        let viewModel = makeViewModel(
            searchSpy: searchSpy,
            addFriendSpy: addFriendSpy,
            isAuthenticated: true
        )

        viewModel.onAppear(isLoggedIn: true)
        viewModel.searchText = profile.username
        await viewModel.searchProfiles()
        await viewModel.addFriend(profile)

        #expect(viewModel.profiles == [profile])
        #expect(viewModel.hasAddedFriend(profile))
        #expect(viewModel.successMessage == "Added @\(profile.username) as a friend.")

        viewModel.authenticationStateChanged(isLoggedIn: false)

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.profiles.isEmpty)
        #expect(viewModel.addedFriendIDs.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.successMessage == nil)
    }

    @MainActor
    private func makeViewModel(
        searchSpy: SearchProfilesSpy? = nil,
        addFriendSpy: AddFriendSpy? = nil,
        searchResults: [UserProfile] = [],
        isAuthenticated: Bool
    ) -> DiscoverViewModel {
        DiscoverViewModel(
            profileRespository: MockProfileRepository(
                searchSpy: searchSpy,
                searchResults: searchResults
            ),
            friendsRepository: MockFriendsRepository(addFriendSpy: addFriendSpy),
            isAuthenticated: isAuthenticated
        )
    }
}
