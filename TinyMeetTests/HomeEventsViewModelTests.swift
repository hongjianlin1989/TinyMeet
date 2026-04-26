import Foundation
import Testing
@testable import TinyMeet

struct HomeEventsViewModelTests {
    struct MockEventsRepository: EventsRepositoryProtocol {
        let publicEvents: [NearbyEvent]
        let privateEvents: [NearbyEvent]

        func fetchPublicEvents() async throws -> [NearbyEvent] {
            publicEvents
        }

        func fetchPrivateEvents() async throws -> [NearbyEvent] {
            privateEvents
        }
    }

    struct MockInterestedEventsRepository: InterestedEventsRepositoryProtocol {
        let interestedRows: [InterestedEventRow]
        let onSetInterested: @Sendable (Bool, UUID) async throws -> Void

        init(
            interestedRows: [InterestedEventRow],
            onSetInterested: @escaping @Sendable (Bool, UUID) async throws -> Void = { _, _ in }
        ) {
            self.interestedRows = interestedRows
            self.onSetInterested = onSetInterested
        }

        func fetchInterestedEvents() async throws -> [InterestedEventRow] {
            interestedRows
        }

        func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
            []
        }

        func setInterested(_ isInterested: Bool, eventID: UUID) async throws {
            try await onSetInterested(isInterested, eventID)
        }
    }

    actor InterestCallRecorder {
        private(set) var calls: [(Bool, UUID)] = []

        func record(isInterested: Bool, eventID: UUID) {
            calls.append((isInterested, eventID))
        }
    }

    @MainActor
    @Test func loadNearbyEventsMarksInterestedRows() async throws {
        let interestedID = UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1")!
        let otherID = UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F")!

        let publicEvent = NearbyEvent(
            id: interestedID,
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

        let privateEvent = NearbyEvent(
            id: otherID,
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            visibility: .private
        )

        let interestedRows = [
            InterestedEventRow(
                id: interestedID,
                source: .nearby(publicEvent)
            )
        ]

        let viewModel = HomeEventsViewModel(
            userDefaults: UserDefaults(suiteName: #function)!,
            eventsRepository: MockEventsRepository(publicEvents: [publicEvent], privateEvents: [privateEvent]),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: interestedRows)
        )

        await viewModel.refreshNearbyEvents()

        #expect(viewModel.events.count == 2)
        #expect(viewModel.events.first(where: { $0.id == interestedID })?.isInterested == true)
        #expect(viewModel.events.first(where: { $0.id == otherID })?.isInterested == false)
    }

    @MainActor
    @Test func toggleInterestCallsRepositoryAndUpdatesEvent() async throws {
        let eventID = UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F")!
        let recorder = InterestCallRecorder()
        let event = NearbyEvent(
            id: eventID,
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            visibility: .private
        )

        let viewModel = HomeEventsViewModel(
            userDefaults: UserDefaults(suiteName: #function)!,
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [event]),
            interestedEventsRepository: MockInterestedEventsRepository(
                interestedRows: [],
                onSetInterested: { isInterested, eventID in
                    await recorder.record(isInterested: isInterested, eventID: eventID)
                }
            )
        )

        await viewModel.refreshNearbyEvents()
        await viewModel.toggleInterest(for: eventID)

        #expect(viewModel.events.first(where: { $0.id == eventID })?.isInterested == true)
        let calls = await recorder.calls
        #expect(calls.count == 1)
        #expect(calls.first?.0 == true)
        #expect(calls.first?.1 == eventID)
    }
}
