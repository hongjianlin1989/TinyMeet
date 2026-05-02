import Testing
import Foundation
@testable import TinyMeet

struct FriendRequestsViewModelTests {
    struct MockProfileRepository: ProfileRespositoryProtocol {
        let fetchFriendRequestsHandler: @Sendable () async throws -> [UserProfile]
        let acceptFriendRequestHandler: @Sendable (UserProfile) async throws -> Void
        let rejectFriendRequestHandler: @Sendable (UserProfile) async throws -> Void

        init(
            fetchFriendRequestsHandler: @escaping @Sendable () async throws -> [UserProfile],
            acceptFriendRequestHandler: @escaping @Sendable (UserProfile) async throws -> Void = { _ in },
            rejectFriendRequestHandler: @escaping @Sendable (UserProfile) async throws -> Void = { _ in }
        ) {
            self.fetchFriendRequestsHandler = fetchFriendRequestsHandler
            self.acceptFriendRequestHandler = acceptFriendRequestHandler
            self.rejectFriendRequestHandler = rejectFriendRequestHandler
        }

        func fetchUserProfile() async throws -> UserProfile { UserProfile.mock }
        func fetchFriendProfiles() async throws -> [UserProfile] { [] }
        func fetchFriendRequests() async throws -> [UserProfile] { try await fetchFriendRequestsHandler() }
        func searchUserProfiles(query: String) async throws -> [UserProfile] { [] }
        func acceptFriendRequest(_ request: UserProfile) async throws { try await acceptFriendRequestHandler(request) }
        func rejectFriendRequest(_ request: UserProfile) async throws { try await rejectFriendRequestHandler(request) }
        func addFriend(_ profile: UserProfile) async throws {}
        func removeFriend(_ profile: UserProfile) async throws {}
    }

    @MainActor
    @Test func loadFriendRequestsPopulatesRequests() async throws {
        let amy = UserProfile(
            id: "request-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let noah = UserProfile(
            id: "request-noahpatel",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: "Mobile engineer",
            age: 29,
            avatarURL: nil
        )

        let viewModel = FriendRequestsViewModel(
            profileRepository: MockProfileRepository(fetchFriendRequestsHandler: { [amy, noah] })
        )

        await viewModel.loadRequests()

        #expect(viewModel.requests.count == 2)
        #expect(viewModel.requests.first?.id == amy.id)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func loadFriendRequestsStoresErrorWhenFetchFails() async throws {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "Failed to load requests" }
        }

        let viewModel = FriendRequestsViewModel(
            profileRepository: MockProfileRepository(fetchFriendRequestsHandler: { throw SampleError() })
        )

        await viewModel.loadRequests()

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.errorMessage == "Failed to load requests")
    }

    @MainActor
    @Test func acceptRemovesHandledRequestAndStoresSuccessMessage() async throws {
        let amy = UserProfile(
            id: "request-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: nil,
            bio: "Coffee meetup organizer",
            age: 27,
            avatarURL: nil
        )
        let viewModel = FriendRequestsViewModel(
            profileRepository: MockProfileRepository(
                fetchFriendRequestsHandler: { [amy] },
                acceptFriendRequestHandler: { request in
                    #expect(request.id == amy.id)
                }
            )
        )

        await viewModel.loadRequests()
        await viewModel.accept(amy)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Accepted @amychen's request.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }

    @MainActor
    @Test func rejectRemovesHandledRequestAndStoresSuccessMessage() async throws {
        let noah = UserProfile(
            id: "request-noahpatel",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: nil,
            bio: "Mobile engineer",
            age: 29,
            avatarURL: nil
        )
        let viewModel = FriendRequestsViewModel(
            profileRepository: MockProfileRepository(
                fetchFriendRequestsHandler: { [noah] },
                rejectFriendRequestHandler: { request in
                    #expect(request.id == noah.id)
                }
            )
        )

        await viewModel.loadRequests()
        await viewModel.reject(noah)

        #expect(viewModel.requests.isEmpty)
        #expect(viewModel.successMessage == "Rejected @noahpatel's request.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.respondingRequestIDs.isEmpty)
    }
}
