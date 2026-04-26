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
    func addFriend(_ profile: UserProfile) async throws
    func removeFriend(_ profile: UserProfile) async throws
}

struct ProfileRespository: ProfileRespositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        shouldUseMockData: Bool = true,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchUserProfile() async throws -> UserProfile {
        let request = try ProfileUrlRequest.getUserProfile.asURLRequest()

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
            return Array(try mockProfiles().dropFirst())
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
            return searchProfiles(try mockProfiles(), matching: trimmedQuery)
        }

        return []
    }

    func addFriend(_ profile: UserProfile) async throws {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(150))
            return
        }

        let request = try ProfileUrlRequest.addFriend(userID: profile.id).asURLRequest()
        let _: AddFriendResponse = try await networkManager.perform(request)
    }

    func removeFriend(_ profile: UserProfile) async throws {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(150))
            return
        }

        let request = try ProfileUrlRequest.removeFriend(userID: profile.id).asURLRequest()
        let _: RemoveFriendResponse = try await networkManager.perform(request)
    }

    private func mockProfiles() throws -> [UserProfile] {
        do {
            let response: UserProfileListResponse = try loadMockResponse(named: "mock_search_profiles")
            return response.items.map { $0.toUserProfile() }
        } catch ProfileRespositoryError.missingMockResource {
            return UserProfile.mockProfiles
        }
    }

    private func searchProfiles(_ profiles: [UserProfile], matching query: String) -> [UserProfile] {
        let normalizedQuery = query.localizedLowercase

        return profiles.filter { profile in
            profile.username.localizedLowercase.contains(normalizedQuery)
                || (profile.bio?.localizedLowercase.contains(normalizedQuery) ?? false)
        }
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ProfileRespositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ProfileRespositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum ProfileRespositoryError: LocalizedError {
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingMockResource(let name):
            return "Missing mock profiles JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock profiles JSON resource \(name).json (\(underlying.localizedDescription))"
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
