import Foundation
import Testing
@testable import TinyMeet

struct EventsRepositoryMockJSONTests {
    @Test func mockJSONDecodesPublicEvents() async throws {
        let repository = EventsRepository(bundle: .main)
        let events = try await repository.fetchPublicEvents()
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.visibility == .public })
        #expect(events.allSatisfy {
            guard let eventUrl = $0.eventUrl,
                  let url = URL(string: eventUrl) else {
                return false
            }

            return url.scheme?.isEmpty == false
        })
    }

    @Test func mockJSONDecodesPrivateEvents() async throws {
        let repository = EventsRepository(bundle: .main)
        let events = try await repository.fetchPrivateEvents()
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.visibility == .private })
    }
}
