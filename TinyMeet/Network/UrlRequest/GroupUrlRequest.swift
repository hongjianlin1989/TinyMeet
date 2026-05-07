import Foundation

enum GroupUrlRequest {
    case list
    case invites
    case respondToInvite(inviteID: String, action: FriendRequestResponseAction)
    case create(CreateGroupRequest)
    case detail(groupID: String)
    case deleteGroup(groupID: String)
    case addMember(groupID: String, name: String)
    case leaveGroup(groupID: String)
    case inviteUserProfile(groupID: String, inviteeUID: String)
    case deleteMember(groupID: String, memberID: String)

    private var path: String {
        switch self {
        case .list, .create:
            return "/groups"
        case .invites:
            return "/groups/invites"
        case .respondToInvite(let inviteID, _):
            return "/groups/invites/\(inviteID)/respond"
        case .detail(let groupID), .deleteGroup(let groupID):
            return "/groups/\(groupID)"
        case .addMember(let groupID, _), .leaveGroup(let groupID):
            return "/groups/\(groupID)/members"
        case .inviteUserProfile(let groupID, _):
            return "/groups/\(groupID)/invites"
        case .deleteMember(let groupID, let memberID):
            return "/groups/\(groupID)/members/\(memberID)"
        }
    }

    private var method: String {
        switch self {
        case .list, .invites, .detail:
            return "GET"
        case .respondToInvite, .create, .addMember, .inviteUserProfile:
            return "POST"
        case .deleteGroup, .leaveGroup, .deleteMember:
            return "DELETE"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = ApiConfig.apiURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = try bodyData() {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func bodyData() throws -> Data? {
        let encoder = JSONEncoder()

        switch self {
        case .list, .invites, .detail, .deleteGroup, .leaveGroup, .deleteMember:
            return nil
        case .respondToInvite(_, let action):
            return try encoder.encode(InviteResponsePayload(accept: action.acceptValue))
        case .create(let request):
            return try encoder.encode(request)
        case .addMember(_, let name):
            return try encoder.encode(AddMemberPayload(name: name))
        case .inviteUserProfile(_, let inviteeUID):
            return try encoder.encode(InviteUserProfilePayload(inviteeUID: inviteeUID))
        }
    }
}

private struct AddMemberPayload: Encodable {
    let name: String
}

private struct InviteUserProfilePayload: Encodable {
    let inviteeUID: String

    private enum CodingKeys: String, CodingKey {
        case inviteeUID = "invitee_uid"
    }
}

private struct InviteResponsePayload: Encodable {
    let accept: Bool
}
