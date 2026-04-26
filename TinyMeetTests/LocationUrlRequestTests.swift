import Foundation
import Testing
@testable import TinyMeet

struct LocationUrlRequestTests {
    @Test func updateCurrentLocationRequestUsesProfileLocationEndpoint() throws {
        let request = try LocationUrlRequest.updateCurrentLocation(latitude: 37.3317, longitude: -122.0325).asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Double])

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path == "/users/profile/location")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["latitude"] == 37.3317)
        #expect(json["longitude"] == -122.0325)
    }
}
