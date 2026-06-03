import Foundation

enum EventsUrlRequest {
    case listPublic
    case listPrivate
    case create(CreateEventRequest)
    case feed(types: [String]?, categories: [String]?, ageGroups: [String]?, postalCode: String?, cursor: String?)

    private var path: String {
        switch self {
        case .listPublic:
            return "/events/public"
        case .listPrivate:
            return "/events/private"
        case .create(let request):
            return request.visibility == .public ? "/events/public" : "/events/private"
        case .feed:
            return "/events/feed"
        }
    }

    private var method: String {
        switch self {
        case .listPublic, .listPrivate, .feed:
            return "GET"
        case .create:
            return "POST"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url: URL
        if case let .feed(types, categories, ageGroups, postalCode, cursor) = self {
            var components = URLComponents(url: ApiConfig.apiURL(path: path), resolvingAgainstBaseURL: false)!
            var queryItems: [URLQueryItem] = []
            for type_ in types ?? [] {
                queryItems.append(URLQueryItem(name: "types", value: type_))
            }
            for category in categories ?? [] {
                queryItems.append(URLQueryItem(name: "category", value: category))
            }
            for ageGroup in ageGroups ?? [] {
                queryItems.append(URLQueryItem(name: "age_group", value: ageGroup))
            }
            if let postalCode {
                queryItems.append(URLQueryItem(name: "postal_code", value: postalCode))
            }
            if let cursor {
                queryItems.append(URLQueryItem(name: "cursor", value: cursor))
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            url = components.url!
        } else {
            url = ApiConfig.apiURL(path: path)
        }

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
        case .listPublic, .listPrivate, .feed:
            return nil
        case .create(let request):
            return try JSONEncoder().encode(request)
        }
    }
}
