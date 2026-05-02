//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
    func fetchFriendProfiles() async throws -> [UserProfile]
    func fetchFriendRequests() async throws -> [UserProfile]
    func searchUserProfiles(query: String) async throws -> [UserProfile]
    func acceptFriendRequest(_ request: UserProfile) async throws
    func rejectFriendRequest(_ request: UserProfile) async throws
    func addFriend(_ profile: UserProfile) async throws
    func removeFriend(_ profile: UserProfile) async throws
}

struct ProfileRespository: ProfileRespositoryProtocol {
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

    func fetchUserProfile() async throws -> UserProfile {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        let response: UserProfileResponse = try await networkManager.perform(request)
        return response.toUserProfile()
    }

    func fetchFriendProfiles() async throws -> [UserProfile] {
        let request = ProfileUrlRequest.friends.asURLRequest()
        let response: FriendListResponse = try await networkManager.perform(request)
        return response.friends.map { $0.toUserProfile() }
    }

    func fetchFriendRequests() async throws -> [UserProfile] {
        let request = ProfileUrlRequest.friendRequests.asURLRequest()
        let response: [FriendRequestRecordResponse] = try await networkManager.perform(request)
        return response.map { $0.toUserProfile() }
    }

    func searchUserProfiles(query: String) async throws -> [UserProfile] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let request = ProfileUrlRequest.searchProfiles(query: trimmedQuery).asURLRequest()
        let response: UserProfileListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toUserProfile() }
    }

    func acceptFriendRequest(_ request: UserProfile) async throws {
        try await respondToFriendRequest(request, action: .accept)
    }

    func rejectFriendRequest(_ request: UserProfile) async throws {
        try await respondToFriendRequest(request, action: .reject)
    }

    func addFriend(_ profile: UserProfile) async throws {
        let request = ProfileUrlRequest.addFriend(userID: profile.id).asURLRequest()
        let _: AddFriendResponse = try await networkManager.perform(request)
    }

    func removeFriend(_ profile: UserProfile) async throws {
    
        let request = ProfileUrlRequest.removeFriend(userID: profile.id).asURLRequest()
        let _: RemoveFriendResponse = try await networkManager.perform(request)
    }

    private func respondToFriendRequest(_ request: UserProfile, action: FriendRequestResponseAction) async throws {
            let apiRequest = ProfileUrlRequest.respondToFriendRequest(requestID: request.id, action: action).asURLRequest()
            let _: FriendRequestResponse = try await networkManager.perform(apiRequest)
    }

    private func searchProfiles(_ profiles: [UserProfile], matching query: String) -> [UserProfile] {
        let normalizedQuery = query.localizedLowercase

        return profiles.filter { profile in
            profile.username.localizedLowercase.contains(normalizedQuery)
                || (profile.bio?.localizedLowercase.contains(normalizedQuery) ?? false)
        }
    }
}

private struct UserProfileListResponse: Decodable, Sendable {
    let items: [UserProfileResponse]
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

private struct AddFriendResponse: Decodable, Sendable {
    let success: Bool?
}

private struct RemoveFriendResponse: Decodable, Sendable {
    let success: Bool?
}

private struct FriendRequestResponse: Decodable, Sendable {
    let success: Bool?
}
