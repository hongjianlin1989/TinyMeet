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
    func searchUserProfiles(query: String) async throws -> [UserProfile]
}

struct ProfileRespository: ProfileRespositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let decoder: JSONDecoder

    init(
        networkManager: NetworkManaging? = nil,
        shouldUseMockData: Bool = true,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
        self.decoder = decoder
    }

    func fetchUserProfile() async throws -> UserProfile {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return UserProfile.mock
        }

        let response: UserProfileResponse = try await networkManager.perform(request)
        return response.toUserProfile()
    }

    func fetchFriendProfiles() async throws -> [UserProfile] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            return Array(UserProfile.mockProfiles.dropFirst())
        }

        return []
    }

    func searchUserProfiles(query: String) async throws -> [UserProfile] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            return UserProfile.mockSearchResults(for: trimmedQuery)
        }

        return []
    }
}
