import Foundation

struct UserProfileListResponse: Decodable, Sendable {
    let items: [UserProfileResponse]
}
