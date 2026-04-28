import Foundation

enum InterestedEventsUrlRequest {
    case listPublic
    case listPrivate
    case interested(eventID: UUID)
    case uninterested(eventID: UUID)

    private var path: String {
        switch self {
        case .listPublic:
            return "/users/interested-events/public"
        case .listPrivate:
            return "/users/interested-events/private"
        case .interested(let eventID), .uninterested(let eventID):
            return "/users/interested-events/\(eventID.uuidString)"
        }
    }

    private var method: String {
        switch self {
        case .listPublic, .listPrivate:
            return "GET"
        case .interested:
            return "POST"
        case .uninterested:
            return "DELETE"
        }
    }

    func asURLRequest() -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if case .interested = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
