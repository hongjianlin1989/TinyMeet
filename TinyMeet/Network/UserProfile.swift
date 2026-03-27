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
            bio: "iOS developer who likes clean SwiftUI architecture and local tech meetups.",
            age: 28,
            avatarURL: URL(string: "https://example.com/avatar-hong.jpg")
        ),
        UserProfile(
            id: 2,
            username: "amychen",
            bio: "Coffee meetup organizer and product designer who loves small group conversations.",
            age: 27,
            avatarURL: URL(string: "https://example.com/avatar-amy.jpg")
        ),
        UserProfile(
            id: 3,
            username: "brianlee",
            bio: "Weekend hiker always looking for a new trail and outdoor community.",
            age: 30,
            avatarURL: URL(string: "https://example.com/avatar-brian.jpg")
        ),
        UserProfile(
            id: 4,
            username: "miapark",
            bio: "SwiftUI builder and indie iOS maker shipping side projects.",
            age: 26,
            avatarURL: URL(string: "https://example.com/avatar-mia.jpg")
        ),
        UserProfile(
            id: 5,
            username: "oliviabrown",
            bio: "Community host who enjoys planning local events and helping new members connect.",
            age: 29,
            avatarURL: URL(string: "https://example.com/avatar-olivia.jpg")
        ),
        UserProfile(
            id: 6,
            username: "lucaskim",
            bio: "Backend engineer who joins startup meetups and coffee chats on weekdays.",
            age: 31,
            avatarURL: URL(string: "https://example.com/avatar-lucas.jpg")
        ),
        UserProfile(
            id: 7,
            username: "sofiawang",
            bio: "UX designer who loves creative communities, coffee chats, and design critique groups.",
            age: 25,
            avatarURL: URL(string: "https://example.com/avatar-sofia.jpg")
        ),
        UserProfile(
            id: 8,
            username: "ethannguyen",
            bio: "Outdoor lover, runner, and regular at Bay Area hiking groups.",
            age: 32,
            avatarURL: URL(string: "https://example.com/avatar-ethan.jpg")
        ),
        UserProfile(
            id: 9,
            username: "chloegarcia",
            bio: "Social planner building welcoming local communities across the Bay Area.",
            age: 26,
            avatarURL: URL(string: "https://example.com/avatar-chloe.jpg")
        ),
        UserProfile(
            id: 10,
            username: "noahpatel",
            bio: "Mobile engineer interested in SwiftUI, maps, and meeting other builders.",
            age: 29,
            avatarURL: URL(string: "https://example.com/avatar-noah.jpg")
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
