import CoreLocation
import Foundation

protocol InterestedEventsRepositoryProtocol: Sendable {
    func fetchInterestedEvents() async throws -> [InterestedEventRow]
    func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail]
    func setInterested(_ isInterested: Bool, event: NearbyEvent) async throws
}

struct InterestedEventsRepository: InterestedEventsRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let eventsRepository: EventsRepositoryProtocol
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        eventsRepository: EventsRepositoryProtocol? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.eventsRepository = eventsRepository ?? EventsRepository(
            bundle: bundle,
            decoder: decoder
        )
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchInterestedEvents() async throws -> [InterestedEventRow] {
        async let recordsResponse = fetchInterestedResponse(
            request: try InterestedEventsUrlRequest.list.asURLRequest()
        )
        async let publicEvents = fetchEvents(for: .public)
        async let privateEvents = fetchEvents(for: .private)

        let (response, publicResults, privateResults) = try await (
            recordsResponse,
            publicEvents,
            privateEvents
        )
        return buildInterestedRows(
            from: response.events,
            publicEvents: publicResults,
            privateEvents: privateResults
        )
    }

    func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
        let response = try await fetchInterestedResponse(
            request: InterestedEventsUrlRequest.list.asURLRequest()
        )

        return buildInterestedPrivatePlaydates(from: response.events)
    }

    func setInterested(_ isInterested: Bool, event: NearbyEvent) async throws {
        let request = (isInterested
            ? try InterestedEventsUrlRequest.interested(
                eventID: event.id,
                eventType: event.visibility,
                locationName: event.locationName
            ).asURLRequest()
            : try InterestedEventsUrlRequest.uninterested(eventID: event.id).asURLRequest()
        )
        let _: InterestedEventMutationResponse = try await networkManager.perform(request)
    }

    private func fetchInterestedResponse(request: URLRequest) async throws -> InterestedEventListResponse {
        return try await networkManager.perform(request)
    }

    private func fetchEvents(for visibility: NearbyEventVisibility) async throws -> [NearbyEvent] {
        switch visibility {
        case .public:
            return try await eventsRepository.fetchPublicEvents()
        case .private:
            return try await eventsRepository.fetchPrivateEvents()
        }
    }

    private func buildInterestedRows(
        from records: [InterestedEventRecordDTO],
        publicEvents: [NearbyEvent],
        privateEvents: [NearbyEvent]
    ) -> [InterestedEventRow] {
        let publicEventsByID = Dictionary(uniqueKeysWithValues: publicEvents.map { ($0.id, $0) })
        let privateEventsByID = Dictionary(uniqueKeysWithValues: privateEvents.map { ($0.id, $0) })

        return records.compactMap { record in
            let event: NearbyEvent?

            switch record.eventType {
            case .public:
                event = publicEventsByID[record.eventID]
            case .private:
                event = privateEventsByID[record.eventID]
            }

            guard let event else {
                return nil
            }

            return InterestedEventRow(
                id: record.eventID,
                source: .nearby(event)
            )
        }
    }

    private func buildInterestedPrivatePlaydates(
        from records: [InterestedEventRecordDTO]
    ) -> [InterestedPlaydateMapDetail] {
        return records.compactMap { record in
            guard record.eventType == .private,
                  let latitude = record.latitude,
                  let longitude = record.longitude else {
                return nil
            }

            let title = nonEmpty(record.title)
                ?? nonEmpty(record.locationName)
                ?? "Private Playdate"
            let subtitle = nonEmpty(record.subtitle)
                ?? nonEmpty(record.locationName)
                ?? "Interested playdate"

            let mapItem = PrivateEventMapItem(
                id: record.eventID,
                title: title,
                subtitle: subtitle,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                tintName: record.tintName ?? "mint",
                symbolName: record.symbolName ?? "house.fill"
            )

            return InterestedPlaydateMapDetail(
                event: mapItem,
                scheduledAt: InterestedEventRecordDTO.parseISO8601Date(record.scheduledAt ?? record.createdAt),
                interestedPeople: (record.interestedPeople ?? []).map { $0.toInterestedPersonLocation() }
            )
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              trimmedValue.isEmpty == false else {
            return nil
        }

        return trimmedValue
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw InterestedEventsRepositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw InterestedEventsRepositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum InterestedEventsRepositoryError: LocalizedError {
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingMockResource(let name):
            return "Missing mock interested events JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock interested events JSON resource \(name).json (\(underlying.localizedDescription))"
        }
    }
}
