import Foundation
import Testing
@testable import TinyMeet

struct EventsUrlRequestTests {
    @Test func listPublicRequestUsesApiV1PublicEventsEndpoint() throws {
        let urlRequest = try EventsUrlRequest.listPublic.asURLRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url?.path == "/api/v1/events/public")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func listPrivateRequestUsesApiV1PrivateEventsEndpoint() throws {
        let urlRequest = try EventsUrlRequest.listPrivate.asURLRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url?.path == "/api/v1/events/private")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func createRequestUsesEventsEndpointAndEncodesBody() throws {
        let createRequest = CreateEventRequest(
            title: "Playground Party",
            locationName: "Central Park",
            timeDescription: "Tomorrow 3pm",
            ageRange: "3 - 5",
            joinVisibility: "friends"
        )

        let urlRequest = try EventsUrlRequest.create(createRequest).asURLRequest()
        let body = try #require(urlRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.url?.path == "/events")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["title"] == "Playground Party")
        #expect(json["locationName"] == "Central Park")
        #expect(json["timeDescription"] == "Tomorrow 3pm")
        #expect(json["ageRange"] == "3 - 5")
        #expect(json["joinVisibility"] == "friends")
    }
}
