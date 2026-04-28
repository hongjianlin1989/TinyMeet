import Foundation
import Testing
@testable import TinyMeet

struct InterestedEventsUrlRequestTests {
    @Test func listRequestUsesInterestedEventsEndpoint() throws {
        let request = try InterestedEventsUrlRequest.list.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/users/interested-events")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == ApiConfig.timeoutInterval)
    }

    @Test func interestedRequestUsesMarkInterestedEndpointAndEncodesPayload() throws {
        let eventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let event = NearbyEvent(
            id: eventID,
            title: "Playground Picnic Crew",
            locationName: "Central Park Playground",
            timeDescription: "Today · 4:00 PM",
            ageRange: "Ages 3-5",
            distanceDescription: "0.4 mi away",
            hostName: "Hosted by Mia",
            attendeeSummary: "8 families going",
            themeEmoji: "🛝",
            summary: "Meet other families for snacks.",
            visibility: .public
        )
        let request = try InterestedEventsUrlRequest.interested(event: event).asURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/v1/events/\(eventID.uuidString)/interested")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["event_type"] == "public")
        #expect(json["location_name"] == "Central Park Playground")
    }
}
