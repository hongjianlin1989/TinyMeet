import Foundation

enum GroupUrlRequest {
    case list
    case create(CreateGroupRequest)
    case detail(groupID: String)
    case addMember(groupID: String, name: String)
    case addUserProfile(groupID: String, userID: String)
    case deleteMember(groupID: String, memberID: String)

    private var path: String {
        switch self {
        case .list, .create:
            return "/api/v1/groups"
        case .detail(let groupID):
            return "/api/v1/groups/\(groupID)"
        case .addMember(let groupID, _), .addUserProfile(let groupID, _):
            return "/api/v1/groups/\(groupID)/members"
        case .deleteMember(let groupID, let memberID):
            return "/api/v1/groups/\(groupID)/members/\(memberID)"
        }
    }

    private var method: String {
        switch self {
        case .list, .detail:
            return "GET"
        case .create, .addMember, .addUserProfile:
            return "POST"
        case .deleteMember:
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
        case .list, .detail, .deleteMember:
            return nil
        case .create(let request):
            return try encoder.encode(request)
        case .addMember(_, let name):
            return try encoder.encode(AddMemberPayload(name: name))
        case .addUserProfile(_, let userID):
            return try encoder.encode(AddUserProfilePayload(userID: userID))
        }
    }
}

private struct AddMemberPayload: Encodable {
    let name: String
}

private struct AddUserProfilePayload: Encodable {
    let userID: String
}
