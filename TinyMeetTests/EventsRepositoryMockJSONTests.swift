import Foundation
import Testing
@testable import TinyMeet

struct EventsRepositoryMockJSONTests {
    @Test func mockJSONDecodesPublicEvents() async throws {
        let repository = EventsRepository(shouldUseMockData: true, bundle: .main)
        let events = try await repository.fetchPublicEvents()
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.visibility == .public })
    }

    @Test func mockJSONDecodesPrivateEvents() async throws {
        let repository = EventsRepository(shouldUseMockData: true, bundle: .main)
        let events = try await repository.fetchPrivateEvents()
        #expect(events.isEmpty == false)
        #expect(events.allSatisfy { $0.visibility == .private })
    }
}
