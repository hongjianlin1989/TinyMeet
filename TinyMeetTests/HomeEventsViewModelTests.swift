import Foundation
import Testing
@testable import TinyMeet

struct HomeEventsViewModelTests {
    struct MockEventsRepository: EventsRepositoryProtocol {
        let publicEvents: [NearbyEvent]
        let privateEvents: [NearbyEvent]
        let unifiedFeedHandler: @Sendable ([String]?, [String]?, [String]?, String?, String?) async throws -> (events: [NearbyEvent], nextCursor: String?)

        init(
            publicEvents: [NearbyEvent],
            privateEvents: [NearbyEvent],
            unifiedFeedHandler: (@Sendable ([String]?, [String]?, [String]?, String?, String?) async throws -> (events: [NearbyEvent], nextCursor: String?))? = nil
        ) {
            self.publicEvents = publicEvents
            self.privateEvents = privateEvents
            self.unifiedFeedHandler = unifiedFeedHandler ?? { _, _, _, _, _ in (publicEvents, nil) }
        }

        func fetchPublicEvents() async throws -> [NearbyEvent] {
            publicEvents
        }

        func fetchPrivateEvents() async throws -> [NearbyEvent] {
            privateEvents
        }

        func fetchUnifiedFeed(
            types: [String]?,
            categories: [String]?,
            ageGroups: [String]?,
            postalCode: String?,
            cursor: String?
        ) async throws -> (events: [NearbyEvent], nextCursor: String?) {
            try await unifiedFeedHandler(types, categories, ageGroups, postalCode, cursor)
        }

        func createEvent(_ request: TinyMeet.CreateEventRequest) async throws -> TinyMeet.NearbyEvent {
            request.toNearbyEvent()
        }
    }

    struct MockInterestedEventsRepository: InterestedEventsRepositoryProtocol {
        func fetchPrivateEventAttendees(eventID: UUID) async throws -> [TinyMeet.InterestedPersonLocation] {
            return []
        }

        let interestedRows: [InterestedEventRow]
        let onSetInterested: @Sendable (Bool, NearbyEvent) async throws -> Void

        init(
            interestedRows: [InterestedEventRow],
            onSetInterested: @escaping @Sendable (Bool, NearbyEvent) async throws -> Void = { _, _ in }
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

        func setInterested(_ isInterested: Bool, event: NearbyEvent) async throws {
            try await onSetInterested(isInterested, event)
        }
    }

    actor InterestCallRecorder {
        private(set) var calls: [(Bool, UUID)] = []

        func record(isInterested: Bool, eventID: UUID) {
            calls.append((isInterested, eventID))
        }
    }

    @MainActor
    final class MockPostalCodeProvider: HomePostalCodeProviding {
        let postalCode: String?

        init(postalCode: String?) {
            self.postalCode = postalCode
        }

        func currentPostalCode() async -> String? {
            postalCode
        }
    }

    actor UnifiedFeedRequestRecorder {
        private(set) var calls: [(types: [String]?, categories: [String]?, ageGroups: [String]?, postalCode: String?, cursor: String?)] = []

        func record(
            types: [String]?,
            categories: [String]?,
            ageGroups: [String]?,
            postalCode: String?,
            cursor: String?
        ) {
            calls.append((types, categories, ageGroups, postalCode, cursor))
        }
    }

    @MainActor
    @Test func loadNearbyEventsMarksInterestedRows() async throws {
        let interestedID = try #require(UUID(uuidString: "B1C4E4C9-4A8E-4F8E-A526-7E4C0F66B0A1"))
        let otherID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let userDefaults = try #require(UserDefaults(suiteName: #function))

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
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(publicEvents: [publicEvent], privateEvents: [privateEvent]),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: interestedRows),
            postalCodeProvider: MockPostalCodeProvider(postalCode: "10001")
        )

        await viewModel.refreshNearbyEvents()

        #expect(viewModel.events.count == 2)
        #expect(viewModel.events.first(where: { $0.id == interestedID })?.isInterested == true)
        #expect(viewModel.events.first(where: { $0.id == otherID })?.isInterested == false)
    }

    @MainActor
    @Test func toggleInterestCallsRepositoryAndUpdatesEvent() async throws {
        let eventID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let userDefaults = try #require(UserDefaults(suiteName: #function))
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
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [event]),
            interestedEventsRepository: MockInterestedEventsRepository(
                interestedRows: [],
                onSetInterested: { isInterested, event in
                    await recorder.record(isInterested: isInterested, eventID: event.id)
                }
            ),
            postalCodeProvider: MockPostalCodeProvider(postalCode: "10001")
        )

        await viewModel.refreshNearbyEvents()
        await viewModel.toggleInterest(for: eventID)

        #expect(viewModel.events.first(where: { $0.id == eventID })?.isInterested == true)
        let calls = await recorder.calls
        #expect(calls.count == 1)
        #expect(calls.first?.0 == true)
        #expect(calls.first?.1 == eventID)
    }

    @MainActor
    @Test func refreshNearbyEventsPreservesServerInterestStateForPrivateEvents() async throws {
        let eventID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let userDefaults = try #require(UserDefaults(suiteName: #function))
        let privateEvent = NearbyEvent(
            id: eventID,
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "Friends",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            isInterested: true,
            visibility: .private
        )

        let viewModel = HomeEventsViewModel(
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(publicEvents: [], privateEvents: [privateEvent]),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: []),
            postalCodeProvider: MockPostalCodeProvider(postalCode: "10001")
        )

        await viewModel.refreshNearbyEvents()

        #expect(viewModel.events.count == 1)
        #expect(viewModel.events.first?.id == eventID)
        #expect(viewModel.events.first?.isInterested == true)
    }

    @MainActor
    @Test func refreshNearbyEventsUsesUnifiedFeedForExternalEventsOnPublicTab() async throws {
        let externalID = try #require(UUID(uuidString: "C2D5E5D0-5B9F-4A9F-B637-8F5D1A77C1B2"))
        let privateID = try #require(UUID(uuidString: "A29EBCB6-8A0D-4E1C-9C88-1D7A331E2F8F"))
        let userDefaults = try #require(UserDefaults(suiteName: #function))
        userDefaults.removePersistentDomain(forName: #function)
        defer { userDefaults.removePersistentDomain(forName: #function) }
        let recorder = UnifiedFeedRequestRecorder()

        let externalEvent = NearbyEvent(
            id: externalID,
            title: "External Event",
            locationName: "Arena",
            timeDescription: "Tomorrow · 5:00 PM",
            ageRange: "Teen",
            distanceDescription: "Ticketmaster",
            hostName: "Arena",
            attendeeSummary: "120 people attending",
            themeEmoji: "🎟️",
            summary: "Big show.",
            eventUrl: "https://example.com/tickets",
            visibility: .external
        )

        let privateEvent = NearbyEvent(
            id: privateID,
            title: "Private Event",
            locationName: "Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Kids",
            distanceDescription: "Friends",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "Invite only.",
            visibility: .private
        )

        let viewModel = HomeEventsViewModel(
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(
                publicEvents: [],
                privateEvents: [privateEvent],
                unifiedFeedHandler: { types, categories, ageGroups, postalCode, cursor in
                    await recorder.record(
                        types: types,
                        categories: categories,
                        ageGroups: ageGroups,
                        postalCode: postalCode,
                        cursor: cursor
                    )
                    return ([externalEvent], nil)
                }
            ),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: []),
            postalCodeProvider: MockPostalCodeProvider(postalCode: "10001")
        )

        await viewModel.refreshNearbyEvents()

        let calls = await recorder.calls
        #expect(calls.count == 1)
        #expect(calls.first?.types == ["external"])
        #expect(calls.first?.postalCode == "10001")
        #expect(viewModel.filteredEvents.map(\.id) == [externalID])

        viewModel.selectFilter(.private)
        #expect(viewModel.filteredEvents.map(\.id) == [privateID])
    }

    @MainActor
    @Test func togglingPublicFiltersRefreshesUnifiedFeedWithSelectedQueryParameters() async throws {
        let userDefaults = try #require(UserDefaults(suiteName: #function))
        userDefaults.removePersistentDomain(forName: #function)
        defer { userDefaults.removePersistentDomain(forName: #function) }
        let recorder = UnifiedFeedRequestRecorder()

        let viewModel = HomeEventsViewModel(
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(
                publicEvents: [],
                privateEvents: [],
                unifiedFeedHandler: { types, categories, ageGroups, postalCode, cursor in
                    await recorder.record(
                        types: types,
                        categories: categories,
                        ageGroups: ageGroups,
                        postalCode: postalCode,
                        cursor: cursor
                    )
                    return ([], nil)
                }
            ),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: []),
            postalCodeProvider: MockPostalCodeProvider(postalCode: "10001")
        )

        await viewModel.toggleCategory(.music)
        await viewModel.toggleAgeGroup(.kids)

        let calls = await recorder.calls
        #expect(calls.count == 2)
        #expect(calls.last?.types == ["external"])
        #expect(calls.last?.categories == ["Music"])
        #expect(calls.last?.ageGroups == ["kids"])
        #expect(viewModel.selectedCategories == [.music])
        #expect(viewModel.selectedAgeGroups == [.kids])
    }

    @MainActor
    @Test func refreshNearbyEventsSkipsExternalFeedWhenPostalCodeUnavailable() async throws {
        let userDefaults = try #require(UserDefaults(suiteName: #function))
        userDefaults.removePersistentDomain(forName: #function)
        defer { userDefaults.removePersistentDomain(forName: #function) }
        let recorder = UnifiedFeedRequestRecorder()

        let viewModel = HomeEventsViewModel(
            userDefaults: userDefaults,
            eventsRepository: MockEventsRepository(
                publicEvents: [],
                privateEvents: [],
                unifiedFeedHandler: { types, categories, ageGroups, postalCode, cursor in
                    await recorder.record(
                        types: types,
                        categories: categories,
                        ageGroups: ageGroups,
                        postalCode: postalCode,
                        cursor: cursor
                    )
                    return ([], nil)
                }
            ),
            interestedEventsRepository: MockInterestedEventsRepository(interestedRows: []),
            postalCodeProvider: MockPostalCodeProvider(postalCode: nil)
        )

        await viewModel.refreshNearbyEvents()

        let calls = await recorder.calls
        #expect(calls.isEmpty)
        #expect(viewModel.publicFeedNoticeMessage == "Allow location access to load nearby external events.")
    }
}
