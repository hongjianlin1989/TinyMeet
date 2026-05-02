import Foundation
import Testing
@testable import TinyMeet

struct CreateEventViewModelTests {
    struct MockEventsRepository: EventsRepositoryProtocol {
        let createHandler: @Sendable (CreateEventRequest) async throws -> NearbyEvent

        init(createHandler: @escaping @Sendable (CreateEventRequest) async throws -> NearbyEvent) {
            self.createHandler = createHandler
        }

        func fetchPublicEvents() async throws -> [NearbyEvent] { [] }
        func fetchPrivateEvents() async throws -> [NearbyEvent] { [] }
        func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
            try await createHandler(request)
        }
    }

    @MainActor
    @Test func createEventSubmitsThroughRepositoryAndStoresCreatedEvent() async throws {
        let created = NearbyEvent(
            title: "Playground Party",
            locationName: "Central Park",
            timeDescription: "Tomorrow 3pm",
            ageRange: "3 - 5",
            distanceDescription: "Just created",
            hostName: "Hosted by You",
            attendeeSummary: "Private invite event",
            themeEmoji: "🎉",
            summary: "A newly created playdate for your TinyMeet community.",
            visibility: .private
        )

        let viewModel = CreateEventViewModel(
            title: "Playground Party",
            location: "Central Park",
            time: "Tomorrow 3pm",
            kidsAge: "3 - 5",
            joinVisibility: .friends,
            eventsRepository: MockEventsRepository(createHandler: { request in
                #expect(request.title == "Playground Party")
                #expect(request.locationName == "Central Park")
                #expect(request.timeDescription == "Tomorrow 3pm")
                #expect(request.ageRange == "3 - 5")
                #expect(request.joinVisibility == "friends")
                return created
            })
        )

        let didCreate = await viewModel.createEvent()
        #expect(didCreate)
        #expect(viewModel.createdEvent == created)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test func createEventReturnsFalseWhenFormIsInvalid() async throws {
        let unexpectedEvent = NearbyEvent(
            title: "Invalid",
            locationName: "Invalid",
            timeDescription: "Invalid",
            ageRange: "Invalid",
            distanceDescription: "Invalid",
            hostName: "Invalid",
            attendeeSummary: "Invalid",
            themeEmoji: "🎉",
            summary: "Invalid",
            visibility: .private
        )

        let viewModel = CreateEventViewModel(
            title: "   ",
            location: "Central Park",
            time: "Tomorrow 3pm",
            kidsAge: "3 - 5",
            eventsRepository: MockEventsRepository(createHandler: { _ in
                Issue.record("Repository should not be called for invalid form")
                return unexpectedEvent
            })
        )

        let didCreate = await viewModel.createEvent()
        #expect(didCreate == false)
        #expect(viewModel.createdEvent == nil)
    }
}
