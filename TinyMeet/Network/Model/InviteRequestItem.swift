import Foundation

struct GroupInvite: Identifiable, Equatable, Sendable {
    let id: String
    let groupID: String
    let groupName: String
    let groupSummary: String?
    let ownerUID: String?
    let createdAt: String?
}

enum InviteRequestItem: Identifiable, Equatable, Sendable {
    case friend(UserProfile)
    case group(GroupInvite)

    var id: String {
        switch self {
        case .friend(let request):
            return "friend:\(request.id)"
        case .group(let invite):
            return "group:\(invite.id)"
        }
    }
}
