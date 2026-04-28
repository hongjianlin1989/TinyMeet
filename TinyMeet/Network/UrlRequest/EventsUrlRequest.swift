import Foundation

enum EventsUrlRequest {
    case listPublic
    case listPrivate
    case create(CreateEventRequest)

    private var path: String {
        switch self {
        case .listPublic:
            return "/api/v1/events/public"
        case .listPrivate:
            return "/api/v1/events/private"
        case .create:
            return "/events"
        }
    }

    private var method: String {
        switch self {
        case .listPublic, .listPrivate:
            return "GET"
        case .create:
            return "POST"
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
        switch self {
        case .listPublic, .listPrivate:
            return nil
        case .create(let request):
            return try JSONEncoder().encode(request)
        }
    }
}
