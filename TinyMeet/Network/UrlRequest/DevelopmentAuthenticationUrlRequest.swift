import Foundation

enum DevelopmentAuthenticationUrlRequest {
    case token(email: String)

    func asURLRequest() throws -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: "/api/v1/dev/token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: TinyMeetNetworkHeader.skipAuthorization)
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private var body: DevelopmentAuthenticationTokenRequestBody {
        switch self {
        case .token(let email):
            return DevelopmentAuthenticationTokenRequestBody(email: email)
        }
    }
}

private struct DevelopmentAuthenticationTokenRequestBody: Encodable {
    let email: String
}
