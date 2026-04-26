import Foundation

enum GroupUrlRequest {
    case list
    case detail(groupID: Int)
    case addMember(groupID: Int, name: String)
    case addUserProfile(groupID: Int, userID: Int)
    case deleteMember(groupID: Int, memberID: Int)

    private var path: String {
        switch self {
        case .list:
            return "/groups"
        case .detail(let groupID):
            return "/groups/\(groupID)"
        case .addMember(let groupID, _), .addUserProfile(let groupID, _):
            return "/groups/\(groupID)/members"
        case .deleteMember(let groupID, let memberID):
            return "/groups/\(groupID)/members/\(memberID)"
        }
    }

    private var method: String {
        switch self {
        case .list, .detail:
            return "GET"
        case .addMember, .addUserProfile:
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
    let userID: Int
}
