//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol: Sendable {
    nonisolated func fetchUserProfile() async throws -> UserProfile
    nonisolated func searchUserProfiles(query: String) async throws -> [UserProfile]
}

struct ProfileRespository: ProfileRespositoryProtocol, Sendable {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging = NetworkManager(),
        shouldUseMockData: Bool = true,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager
        self.shouldUseMockData = shouldUseMockData
        self.decoder = decoder
    }

    nonisolated func fetchUserProfile() async throws -> UserProfile {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return UserProfile.mock
        }

        let response = try await networkManager.perform(request) as UserProfileResponse
        return response.toUserProfile()
    }

    nonisolated func searchUserProfiles(query: String) async throws -> [UserProfile] {
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
