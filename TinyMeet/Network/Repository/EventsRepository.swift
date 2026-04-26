import Foundation

protocol EventsRepositoryProtocol: Sendable {
    func fetchPublicEvents() async throws -> [NearbyEvent]
    func fetchPrivateEvents() async throws -> [NearbyEvent]
    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent
}

struct EventsRepository: EventsRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        shouldUseMockData: Bool = true,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchPublicEvents() async throws -> [NearbyEvent] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            let response: EventsListResponse = try loadMockResponse(named: "public_events")
            return response.items.map { $0.toNearbyEvent(visibility: .public) }
        }

        let request = try EventsUrlRequest.listPublic.asURLRequest()
        let response: EventsListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toNearbyEvent(visibility: .public) }
    }

    func fetchPrivateEvents() async throws -> [NearbyEvent] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            let response: EventsListResponse = try loadMockResponse(named: "private_events")
            return response.items.map { $0.toNearbyEvent(visibility: .private) }
        }

        let request = try EventsUrlRequest.listPrivate.asURLRequest()
        let response: EventsListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toNearbyEvent(visibility: .private) }
    }

    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(200))
            return request.toNearbyEvent()
        }

        let urlRequest = try EventsUrlRequest.create(request).asURLRequest()
        let response: EventDTO = try await networkManager.perform(urlRequest)
        return response.toNearbyEvent(visibility: request.nearbyEventVisibility)
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw EventsRepositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw EventsRepositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum EventsRepositoryError: LocalizedError {
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingMockResource(let name):
            return "Missing mock events JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock events JSON resource \(name).json (\(underlying.localizedDescription))"
        }
    }
}

struct EventsListResponse: Decodable, Sendable {
    let items: [EventDTO]
}

struct EventDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let locationName: String
    let timeDescription: String
    let ageRange: String
    let distanceDescription: String
    let hostName: String
    let attendeeSummary: String
    let themeEmoji: String
    let summary: String
    let eventUrl: String?

    func toNearbyEvent(visibility: NearbyEventVisibility) -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName,
            timeDescription: timeDescription,
            ageRange: ageRange,
            distanceDescription: distanceDescription,
            hostName: hostName,
            attendeeSummary: attendeeSummary,
            themeEmoji: themeEmoji,
            summary: summary,
            eventUrl: eventUrl,
            visibility: visibility
        )
    }
}

struct CreateEventRequest: Encodable, Sendable {
    let title: String
    let locationName: String
    let timeDescription: String
    let ageRange: String
    let joinVisibility: String

    var nearbyEventVisibility: NearbyEventVisibility {
        joinVisibility == "public" ? .public : .private
    }

    func toNearbyEvent(id: UUID = UUID()) -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName,
            timeDescription: timeDescription,
            ageRange: ageRange,
            distanceDescription: "Just created",
            hostName: "Hosted by You",
            attendeeSummary: joinVisibility == "public" ? "New public event" : "Private invite event",
            themeEmoji: "🎉",
            summary: "A newly created playdate for your TinyMeet community.",
            eventUrl: nil,
            visibility: nearbyEventVisibility
        )
    }
}
