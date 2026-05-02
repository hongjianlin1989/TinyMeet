import Foundation
import Testing
@testable import TinyMeet

struct DevelopmentAuthenticationUrlRequestTests {
    @Test func tokenRequestUsesDevTokenEndpointAndBody() throws {
        let request = try DevelopmentAuthenticationUrlRequest.token(email: "dev@example.com").asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/dev/token")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: TinyMeetNetworkHeader.skipAuthorization) == "true")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["email"] == "dev@example.com")
    }
}
