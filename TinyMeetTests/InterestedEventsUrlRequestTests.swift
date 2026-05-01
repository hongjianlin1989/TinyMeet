import Foundation
import Testing
@testable import TinyMeet

struct InterestedEventsUrlRequestTests {
    @Test func listRequestUsesInterestedEventsEndpoint() throws {
        let request = try InterestedEventsUrlRequest.list.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/api/v1/events/interested")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == ApiConfig.timeoutInterval)
    }

    @Test func interestedRequestUsesPostEndpointAndBody() throws {
        let eventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let request = try InterestedEventsUrlRequest.interested(
            eventID: eventID,
            eventType: .public,
            locationName: "Central Park Playground"
        ).asURLRequest()
        let body = try #require(request.httpBody)
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: String]

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/events/\(eventID.uuidString)/interested")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(payload?["event_type"] == "public")
        #expect(payload?["location_name"] == "Central Park Playground")
    }

    @Test func uninterestedRequestUsesDeleteEndpoint() throws {
        let eventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let request = try InterestedEventsUrlRequest.uninterested(eventID: eventID).asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/api/v1/events/\(eventID.uuidString)/interested")
        #expect(request.httpBody == nil)
    }
}
