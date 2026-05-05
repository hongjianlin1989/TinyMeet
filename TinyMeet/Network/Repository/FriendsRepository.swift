import Foundation

protocol FriendsRepositoryProtocol: Sendable {
    func fetchFriendProfiles() async throws -> [UserProfile]
    func fetchFriendRequests() async throws -> [UserProfile]
    func acceptFriendRequest(_ request: UserProfile) async throws
    func rejectFriendRequest(_ request: UserProfile) async throws
    func addFriend(_ profile: UserProfile) async throws
    func removeFriend(_ profile: UserProfile) async throws
}

struct FriendsRepository: FriendsRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchFriendProfiles() async throws -> [UserProfile] {
        let request = FriendsUrlRequest.friends.asURLRequest()
        let response: FriendListResponse = try await networkManager.perform(request)
        return response.friends.map { $0.toUserProfile() }
    }

    func fetchFriendRequests() async throws -> [UserProfile] {
        let request = FriendsUrlRequest.friendRequests.asURLRequest()
        let response: [FriendRequestRecordResponse] = try await networkManager.perform(request)
        return response.map { $0.toUserProfile() }
    }

    func acceptFriendRequest(_ request: UserProfile) async throws {
        try await respondToFriendRequest(request, action: .accept)
    }

    func rejectFriendRequest(_ request: UserProfile) async throws {
        try await respondToFriendRequest(request, action: .reject)
    }

    func addFriend(_ profile: UserProfile) async throws {
        let request = FriendsUrlRequest.addFriend(userID: profile.id).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(request)
    }

    func removeFriend(_ profile: UserProfile) async throws {
        let request = FriendsUrlRequest.removeFriend(userID: profile.id).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(request)
    }

    private func respondToFriendRequest(_ request: UserProfile, action: FriendRequestResponseAction) async throws {
        let apiRequest = FriendsUrlRequest.respondToFriendRequest(requestID: request.id, action: action).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(apiRequest)
    }
}

private struct FriendListResponse: Decodable, Sendable {
    let friends: [FriendProfileResponse]
}

private struct FriendProfileResponse: Decodable, Sendable {
    let uid: String
    let friendUID: String
    let displayName: String?
    let avatarURL: URL?
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case uid
        case friendUID = "friend_uid"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    func toUserProfile() -> UserProfile {
        let resolvedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackDisplayName = resolvedDisplayName?.isEmpty == false ? resolvedDisplayName! : friendUID

        return UserProfile(
            id: friendUID,
            username: friendUID,
            displayName: fallbackDisplayName,
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: avatarURL
        )
    }
}

private struct FriendRequestRecordResponse: Decodable, Sendable {
    let id: String
    let requesterUID: String
    let receiverUID: String
    let status: String
    let createdAt: String
    let respondedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case requesterUID = "requester_uid"
        case receiverUID = "receiver_uid"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            username: requesterUID,
            displayName: requesterUID,
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
    }
}
