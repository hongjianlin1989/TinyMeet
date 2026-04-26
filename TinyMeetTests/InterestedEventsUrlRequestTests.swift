import Foundation
import Testing
@testable import TinyMeet

struct InterestedEventsUrlRequestTests {
    @Test func listRequestUsesInterestedEventsEndpoint() {
        let request = InterestedEventsUrlRequest.list.asURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/users/interested-events")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.timeoutInterval == ApiConfig.timeoutInterval)
    }

    @Test func interestedRequestUsesPostEndpoint() {
        let eventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let request = InterestedEventsUrlRequest.interested(eventID: eventID).asURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/users/interested-events/\(eventID.uuidString)")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func uninterestedRequestUsesDeleteEndpoint() {
        let eventID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let request = InterestedEventsUrlRequest.uninterested(eventID: eventID).asURLRequest()

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/users/interested-events/\(eventID.uuidString)")
        #expect(request.httpBody == nil)
    }
}
