//
//  ProfileRespository.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol ProfileRespositoryProtocol {
    func fetchUserProfile() async throws -> UserProfile
}

struct ProfileRespository: ProfileRespositoryProtocol {
    private let networkManager: NetworkManaging
    private let maxCacheAge: TimeInterval

    init(
        networkManager: NetworkManaging? = nil,
        maxCacheAge: TimeInterval = 60
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.maxCacheAge = maxCacheAge
    }

    func fetchUserProfile() async throws -> UserProfile {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()
        let userProfile = try await self.networkManager.perform(request) as UserProfile
        return userProfile
    }
}
