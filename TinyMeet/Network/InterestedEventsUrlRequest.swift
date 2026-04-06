import Foundation

enum InterestedEventsUrlRequest {
    case list

    private var path: String {
        switch self {
        case .list:
            return "/users/interested-events"
        }
    }

    private var method: String {
        switch self {
        case .list:
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
