import Foundation

protocol EventsRepositoryProtocol: Sendable {
    func fetchPublicEvents() async throws -> [NearbyEvent]
    func fetchPrivateEvents() async throws -> [NearbyEvent]
    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent
    func fetchUnifiedFeed(types: [String]?, postalCode: String?, cursor: String?) async throws -> (events: [NearbyEvent], nextCursor: String?)
}

struct EventsRepository: EventsRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchPublicEvents() async throws -> [NearbyEvent] {
        let request = try EventsUrlRequest.listPublic.asURLRequest()
        let response: PublicEventsResponse = try await networkManager.perform(request)
        return response.events.map { $0.toNearbyEvent() }
    }

    func fetchPrivateEvents() async throws -> [NearbyEvent] {
        let request = try EventsUrlRequest.listPrivate.asURLRequest()
        let response: PrivateEventsResponse = try await networkManager.perform(request)
        return response.events.map { $0.toNearbyEvent() }
    }

    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
        let urlRequest = try EventsUrlRequest.create(request).asURLRequest()
        let _: CreateEventResponse = try await networkManager.perform(urlRequest)
        return request.toNearbyEvent()
    }

    func fetchUnifiedFeed(
        types: [String]? = nil,
        postalCode: String? = nil,
        cursor: String? = nil
    ) async throws -> (events: [NearbyEvent], nextCursor: String?) {
        let request = try EventsUrlRequest.feed(types: types, postalCode: postalCode, cursor: cursor).asURLRequest()
        let response: UnifiedFeedResponse = try await networkManager.perform(request)
        let events = response.events.map { $0.toNearbyEvent() }
        return (events, response.nextCursor)
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
