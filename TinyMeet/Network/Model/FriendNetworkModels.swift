import Foundation

struct FriendListResponse: Decodable, Sendable {
    let friends: [FriendProfileResponse]
}

struct FriendProfileResponse: Decodable, Sendable {
    let uid: String
    let friendUID: String
    let displayName: String?
    let avatarURL: URL?
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case uid
        case friendUID = "friend_uid"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    func toUserProfile() -> UserProfile {
        let resolvedDisplayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackDisplayName = resolvedDisplayName?.isEmpty == false ? resolvedDisplayName! : friendUID

        return UserProfile(
            id: friendUID,
            username: friendUID,
            displayName: fallbackDisplayName,
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: avatarURL
        )
    }
}

struct FriendRequestRecordResponse: Decodable, Sendable {
    let id: String
    let requesterUID: String
    let receiverUID: String
    let status: String
    let createdAt: String
    let respondedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case requesterUID = "requester_uid"
        case receiverUID = "receiver_uid"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }

    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            username: requesterUID,
            displayName: requesterUID,
            email: nil,
            bio: nil,
            age: nil,
            avatarURL: nil
        )
    }
}
