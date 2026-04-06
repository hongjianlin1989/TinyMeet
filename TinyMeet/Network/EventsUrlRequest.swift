import Foundation

enum EventsUrlRequest {
    case listPublic
    case listPrivate

    private var path: String {
        switch self {
        case .listPublic:
            return "/events/public"
        case .listPrivate:
            return "/events/private"
        }
    }

    private var method: String {
        switch self {
        case .listPublic, .listPrivate:
            return "GET"
        }
    }

    func asURLRequest() -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
