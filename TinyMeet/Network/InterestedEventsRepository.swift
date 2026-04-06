internal import _LocationEssentials
import Foundation

protocol InterestedEventsRepositoryProtocol: Sendable {
    func fetchInterestedEvents() async throws -> [InterestedEventRow]
}

struct InterestedEventsRepository: InterestedEventsRepositoryProtocol {
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

    func fetchInterestedEvents() async throws -> [InterestedEventRow] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            let response: InterestedEventsResponse = try loadMockResponse(named: "interested_events")
            return response.items.map { $0.toInterestedEventRow() }
        }

        let request = InterestedEventsUrlRequest.list.asURLRequest()
        let response: InterestedEventsResponse = try await networkManager.perform(request)
        return response.items.map { $0.toInterestedEventRow() }
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

struct InterestedEventsResponse: Decodable, Sendable {
    let items: [InterestedEventDTO]
}

struct InterestedEventDTO: Decodable, Sendable {
    enum Visibility: String, Decodable, Sendable {
        case `public`
        case `private`
    }

    enum Kind: String, Decodable, Sendable {
        case nearby
        case privateMap
    }

    let id: UUID
    let kind: Kind
    let visibility: Visibility
    let title: String
    let subtitle: String
    let symbolName: String?

    func toInterestedEventRow() -> InterestedEventRow {
        switch kind {
        case .nearby:
            let event = NearbyEvent(
                id: id,
                title: title,
                locationName: "",
                timeDescription: subtitle,
                ageRange: "",
                distanceDescription: "",
                hostName: "",
                attendeeSummary: "",
                themeEmoji: "",
                summary: "",
                visibility: visibility == .private ? .private : .public
            )
            return InterestedEventRow(id: id, source: .nearby(event))

        case .privateMap:
            let mapItem = PrivateEventMapItem(
                id: id,
                title: title,
                subtitle: subtitle,
                coordinate: .init(latitude: 0, longitude: 0),
                tintName: "mint",
                symbolName: symbolName ?? "house.fill"
            )
            return InterestedEventRow(id: id, source: .privateMap(mapItem))
        }
    }
}
