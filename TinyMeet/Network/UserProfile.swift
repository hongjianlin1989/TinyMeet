//
//  UserProfile.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

struct UserProfile: Identifiable, Equatable, Sendable {
    let id: Int
    let username: String
    let bio: String?
    let age: Int?
    let avatarURL: URL?
}

struct UserProfileResponse: Codable, Sendable {
    let id: Int
    let username: String
    let bio: String?
    let age: Int?
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case bio
        case age
        case avatarURL = "avatar_url"
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            username: username,
            bio: bio,
            age: age,
            avatarURL: avatarURL
        )
    }
}

extension UserProfile {
    nonisolated static let mock = mockProfiles[0]

    nonisolated static let mockProfiles: [UserProfile] = [
        UserProfile(
            id: 1,
            username: "hongjianlin1989",
            bio: "iOS developer who likes clean SwiftUI architecture.",
            age: 28,
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        ),
        UserProfile(
            id: 2,
            username: "amychen",
            bio: "Coffee meetup organizer and product designer.",
            age: 27,
            avatarURL: URL(string: "https://example.com/amy.jpg")
        ),
        UserProfile(
            id: 3,
            username: "brianlee",
            bio: "Weekend hiker always looking for a new trail.",
            age: 30,
            avatarURL: URL(string: "https://example.com/brian.jpg")
        ),
        UserProfile(
            id: 4,
            username: "miapark",
            bio: "SwiftUI builder and iOS indie hacker.",
            age: 26,
            avatarURL: URL(string: "https://example.com/mia.jpg")
        ),
        UserProfile(
            id: 5,
            username: "oliviabrown",
            bio: "Community host who enjoys planning local events.",
            age: 29,
            avatarURL: URL(string: "https://example.com/olivia.jpg")
        )
    ]

    nonisolated static func mockSearchResults(for query: String) -> [UserProfile] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let normalizedQuery = trimmedQuery.localizedLowercase
        return mockProfiles.filter { profile in
            profile.username.localizedLowercase.contains(normalizedQuery)
                || (profile.bio?.localizedLowercase.contains(normalizedQuery) ?? false)
        }
    }
}
