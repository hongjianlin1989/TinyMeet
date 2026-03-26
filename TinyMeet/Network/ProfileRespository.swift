//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol: Sendable {
    func fetchUserProfile() async throws -> UserProfile
}

struct ProfileRespository: ProfileRespositoryProtocol, Sendable {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let decoder: JSONDecoder

    init(
        networkManager: NetworkManaging = NetworkManager(),
        shouldUseMockData: Bool = true,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager
        self.shouldUseMockData = shouldUseMockData
        self.decoder = decoder
    }

    func fetchUserProfile() async throws -> UserProfile {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return UserProfile.mock
        }

        let response = try await networkManager.perform(request) as UserProfileResponse
        return response.toUserProfile()
    }
}
