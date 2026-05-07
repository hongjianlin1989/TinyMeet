//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
    func searchUserProfiles(query: String) async throws -> [UserProfile]
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

    func searchUserProfiles(query: String) async throws -> [UserProfile] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let request = ProfileUrlRequest.searchProfiles(query: trimmedQuery).asURLRequest()
        let response: UserProfileListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toUserProfile() }
    }
}
