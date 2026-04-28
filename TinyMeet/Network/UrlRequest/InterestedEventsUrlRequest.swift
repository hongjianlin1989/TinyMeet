import Foundation

enum InterestedEventsUrlRequest {
    case list
    case interested(event: NearbyEvent)

    private var path: String {
        switch self {
        case .list:
            return "/users/interested-events"
        case .interested(let event):
            return "/api/v1/events/\(event.id.uuidString)/interested"
        }
    }

    private var method: String {
        switch self {
        case .list:
            return "GET"
        case .interested:
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
        case .list:
            return nil
        case .interested(let event):
            let payload = MarkInterestedRequestPayload(
                eventType: event.visibility.rawValue,
                locationName: event.locationName.isEmpty ? nil : event.locationName
            )
            return try JSONEncoder().encode(payload)
        }
    }
}

private struct MarkInterestedRequestPayload: Encodable {
    let eventType: String
    let locationName: String?

    private enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case locationName = "location_name"
    }
}
