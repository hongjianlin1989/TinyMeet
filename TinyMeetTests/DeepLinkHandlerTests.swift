import Foundation
import Testing
@testable import TinyMeet

@MainActor
struct DeepLinkHandlerTests {
    @Test func eventDetailURLUsesTinyMeetScheme() throws {
        let eventID = try #require(UUID(uuidString: "0B8EE6EA-3D95-4F4F-BE98-59B464AF6A34"))

        let url = DeepLinkHandler.eventDetailURL(for: eventID)

        #expect(url.absoluteString == "tinymeet://events/0b8ee6ea-3d95-4f4f-be98-59b464af6a34")
        #expect(DeepLinkHandler.destination(for: url) == .eventDetail(eventID: eventID))
    }

    @Test func httpsEventDetailURLParsesToEventDestination() throws {
        let eventID = try #require(UUID(uuidString: "C1F95F7A-A8D2-4D1F-8AA5-8B6E6B73D5A0"))
        let url = try #require(URL(string: "https://tinymeet.app/events/\(eventID.uuidString.lowercased())"))

        #expect(DeepLinkHandler.destination(for: url) == .eventDetail(eventID: eventID))
    }

    @MainActor
    @Test func handlePublishesEventDestination() throws {
        let eventID = try #require(UUID(uuidString: "8D52D00F-3F6E-4DBA-99D9-179F50D1E5E1"))
        let handler = DeepLinkHandler()

        let handled = handler.handle(DeepLinkHandler.eventDetailURL(for: eventID))

        #expect(handled)
        #expect(handler.activeDestination == .eventDetail(eventID: eventID))
    }
}

