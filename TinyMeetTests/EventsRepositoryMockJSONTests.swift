import Foundation
import Testing
@testable import TinyMeet

struct EventsRepositoryMockJSONTests {

    @Test func mockJSONDecodesPrivateEvents() async throws {
        let repository = EventsRepository(bundle: .main)
        let events = try await repository.fetchPrivateEvents()
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.visibility == .private })
    }
}
