import Foundation

enum InterestedEventsUrlRequest {
    case list
    case interested(eventID: UUID, eventType: NearbyEventVisibility, locationName: String?)
    case uninterested(eventID: UUID)

    private var path: String {
        switch self {
        case .list:
            return "/api/v1/events/interested"
        case .interested(let eventID, _, _), .uninterested(let eventID):
            return "/api/v1/events/\(eventID.uuidString)/interested"
        }
    }

    private var method: String {
        switch self {
        case .list:
            return "GET"
        case .interested:
            return "POST"
        case .uninterested:
            return "DELETE"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if case .interested(_, _, _) = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(markInterestedBody)
        }

        return request
    }

    private var markInterestedBody: MarkInterestedRequest {
        switch self {
        case .interested(_, let eventType, let locationName):
            return MarkInterestedRequest(eventType: eventType.rawValue, locationName: locationName)
        case .list, .uninterested:
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
