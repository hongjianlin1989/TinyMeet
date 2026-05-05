import Foundation
import Testing
@testable import TinyMeet

struct ProfileUrlRequestTests {
    @Test func getUserProfileRequestUsesApiV1ProfileEndpoint() {
        let request = ProfileUrlRequest.getUserProfile.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/users/profile")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func searchProfilesRequestUsesSearchEndpointAndTrimmedQueryValue() {
        let request = ProfileUrlRequest.searchProfiles(query: "amy chen").asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/users/search")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        let queryItem = URLComponents(url: try! #require(request.url), resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "query" })
        #expect(queryItem?.value == "amy chen")
    }
}
