//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
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

    func fetchFriendRequests() async throws -> [UserProfile] {
        let request = ProfileUrlRequest.friendRequests.asURLRequest()
        let response: UserProfileListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toUserProfile() }
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

private struct AddFriendResponse: Decodable, Sendable {
    let success: Bool?
}

private struct RemoveFriendResponse: Decodable, Sendable {
    let success: Bool?
}

private struct FriendRequestResponse: Decodable, Sendable {
    let success: Bool?
}
