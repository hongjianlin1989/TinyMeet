import Foundation

enum GroupUrlRequest {
    case list
    case create(CreateGroupRequest)
    case detail(groupID: String)
    case deleteGroup(groupID: String)
    case addMember(groupID: String, name: String)
    case inviteUserProfile(groupID: String, inviteeUID: String)
    case deleteMember(groupID: String, memberID: String)

    private var path: String {
        switch self {
        case .list, .create:
            return "/api/v1/groups"
        case .detail(let groupID), .deleteGroup(let groupID):
            return "/api/v1/groups/\(groupID)"
        case .addMember(let groupID, _):
            return "/api/v1/groups/\(groupID)/members"
        case .inviteUserProfile(let groupID, _):
            return "/api/v1/groups/\(groupID)/invites"
        case .deleteMember(let groupID, let memberID):
            return "/api/v1/groups/\(groupID)/members/\(memberID)"
        }
    }

    private var method: String {
        switch self {
        case .list, .detail:
            return "GET"
        case .create, .addMember, .inviteUserProfile:
            return "POST"
        case .deleteGroup, .deleteMember:
            return "DELETE"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
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
        case .list, .detail, .deleteGroup, .deleteMember:
            return nil
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
