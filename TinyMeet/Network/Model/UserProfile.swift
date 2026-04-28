//
//  UserProfile.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

struct UserProfile: Identifiable, Equatable, Sendable {
    let id: String
    let username: String
    let displayName: String
    let email: String?
    let bio: String?
    let age: Int?
    let avatarURL: URL?
}

struct UserProfileResponse: Codable, Sendable {
    let id: String
    let username: String
    let displayName: String?
    let email: String?
    let bio: String?
    let age: Int?
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case email
        case bio
        case age
        case avatarURL = "avatar_url"
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            username: username,
            displayName: displayName ?? username,
            email: email,
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
            id: "user-hongjianlin1989",
            username: "hongjianlin1989",
            displayName: "Hongjian Lin",
            email: "hongjianlin@example.com",
            bio: "iOS developer who likes clean SwiftUI architecture and local tech meetups.",
            age: 28,
            avatarURL: URL(string: "https://example.com/avatar-hong.jpg")
        ),
        UserProfile(
            id: "user-amychen",
            username: "amychen",
            displayName: "Amy Chen",
            email: "amychen@example.com",
            bio: "Coffee meetup organizer and product designer who loves small group conversations.",
            age: 27,
            avatarURL: URL(string: "https://example.com/avatar-amy.jpg")
        ),
        UserProfile(
            id: "user-brianlee",
            username: "brianlee",
            displayName: "Brian Lee",
            email: "brianlee@example.com",
            bio: "Weekend hiker always looking for a new trail and outdoor community.",
            age: 30,
            avatarURL: URL(string: "https://example.com/avatar-brian.jpg")
        ),
        UserProfile(
            id: "user-miapark",
            username: "miapark",
            displayName: "Mia Park",
            email: "miapark@example.com",
            bio: "SwiftUI builder and indie iOS maker shipping side projects.",
            age: 26,
            avatarURL: URL(string: "https://example.com/avatar-mia.jpg")
        ),
        UserProfile(
            id: "user-oliviabrown",
            username: "oliviabrown",
            displayName: "Olivia Brown",
            email: "oliviabrown@example.com",
            bio: "Community host who enjoys planning local events and helping new members connect.",
            age: 29,
            avatarURL: URL(string: "https://example.com/avatar-olivia.jpg")
        ),
        UserProfile(
            id: "user-lucaskim",
            username: "lucaskim",
            displayName: "Lucas Kim",
            email: "lucaskim@example.com",
            bio: "Backend engineer who joins startup meetups and coffee chats on weekdays.",
            age: 31,
            avatarURL: URL(string: "https://example.com/avatar-lucas.jpg")
        ),
        UserProfile(
            id: "user-sofiawang",
            username: "sofiawang",
            displayName: "Sofia Wang",
            email: "sofiawang@example.com",
            bio: "UX designer who loves creative communities, coffee chats, and design critique groups.",
            age: 25,
            avatarURL: URL(string: "https://example.com/avatar-sofia.jpg")
        ),
        UserProfile(
            id: "user-ethannguyen",
            username: "ethannguyen",
            displayName: "Ethan Nguyen",
            email: "ethannguyen@example.com",
            bio: "Outdoor lover, runner, and regular at Bay Area hiking groups.",
            age: 32,
            avatarURL: URL(string: "https://example.com/avatar-ethan.jpg")
        ),
        UserProfile(
            id: "user-chloegarcia",
            username: "chloegarcia",
            displayName: "Chloe Garcia",
            email: "chloegarcia@example.com",
            bio: "Social planner building welcoming local communities across the Bay Area.",
            age: 26,
            avatarURL: URL(string: "https://example.com/avatar-chloe.jpg")
        ),
        UserProfile(
            id: "user-noahpatel",
            username: "noahpatel",
            displayName: "Noah Patel",
            email: "noahpatel@example.com",
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
