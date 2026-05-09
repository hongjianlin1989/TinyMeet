import Foundation

enum LocationUrlRequest {
    case updateCurrentLocation(latitude: Double, longitude: Double)

    private var path: String {
        switch self {
        case .updateCurrentLocation:
            return "/users/location"
        }
    }

    private var method: String {
        switch self {
        case .updateCurrentLocation:
            return "PUT"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = ApiConfig.apiURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private var body: UpdateCurrentLocationPayload {
        switch self {
        case .updateCurrentLocation(let latitude, let longitude):
            return UpdateCurrentLocationPayload(latitude: latitude, longitude: longitude)
        }
    }
}

private struct UpdateCurrentLocationPayload: Encodable {
    let latitude: Double
    let longitude: Double
}
