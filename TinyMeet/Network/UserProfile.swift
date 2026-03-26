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
    static let mock = UserProfile(
        id: 1,
        username: "hongjianlin1989",
        bio: "iOS developer who likes clean SwiftUI architecture.",
        age: 28,
        avatarURL: URL(string: "https://example.com/avatar.jpg")
    )
}
