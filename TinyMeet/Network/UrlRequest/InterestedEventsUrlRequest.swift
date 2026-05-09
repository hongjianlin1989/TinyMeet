import Foundation

enum InterestedEventsUrlRequest {
    case list
    case attendees(eventID: UUID, eventType: NearbyEventVisibility)
    case interested(eventID: UUID, eventType: NearbyEventVisibility, locationName: String?)
    case uninterested(eventID: UUID)

    private var path: String {
        switch self {
        case .list:
            return "/events/interested"
        case .attendees(let eventID, _):
            return "/events/\(eventID.uuidString)/attendees"
        case .interested(let eventID, _, _), .uninterested(let eventID):
            return "/events/\(eventID.uuidString)/interested"
        }
    }

    private var method: String {
        switch self {
        case .list, .attendees:
            return "GET"
        case .interested:
            return "POST"
        case .uninterested:
            return "DELETE"
        }
    }

    func asURLRequest() throws -> URLRequest {
        var components = URLComponents(url: ApiConfig.apiURL(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case .interested:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(markInterestedBody)
        case .list, .attendees, .uninterested:
            break
        }

        return request
    }

    private var queryItems: [URLQueryItem]? {
        switch self {
        case .attendees(_, let eventType):
            return [URLQueryItem(name: "event_type", value: eventType.rawValue)]
        case .list, .interested, .uninterested:
            return nil
        }
    }

    private var markInterestedBody: MarkInterestedRequest {
        switch self {
        case .interested(_, let eventType, let locationName):
            return MarkInterestedRequest(eventType: eventType.rawValue, locationName: locationName)
        case .list, .attendees, .uninterested:
            fatalError("markInterestedBody is only available for interested requests")
        }
    }
}

private struct MarkInterestedRequest: Encodable {
    let eventType: String
    let locationName: String?

    private enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case locationName = "location_name"
    }
}
