import CoreLocation
import Foundation

protocol InterestedEventsRepositoryProtocol: Sendable {
    func fetchInterestedEvents() async throws -> [InterestedEventRow]
    func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail]
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

    func fetchInterestedPrivatePlaydates() async throws -> [InterestedPlaydateMapDetail] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            let response: InterestedEventsResponse = try loadMockResponse(named: "interested_events")
            return response.items.compactMap { $0.toInterestedPrivatePlaydate() }
        }

        let request = InterestedEventsUrlRequest.list.asURLRequest()
        let response: InterestedEventsResponse = try await networkManager.perform(request)
        return response.items.compactMap { $0.toInterestedPrivatePlaydate() }
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
    let tintName: String?
    let latitude: Double?
    let longitude: Double?
    let scheduledAt: String?
    let interestedPeople: [InterestedPersonLocationDTO]?

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
                coordinate: .init(latitude: latitude ?? 0, longitude: longitude ?? 0),
                tintName: tintName ?? "mint",
                symbolName: symbolName ?? "house.fill"
            )
            return InterestedEventRow(id: id, source: .privateMap(mapItem))
        }
    }

    func toInterestedPrivatePlaydate() -> InterestedPlaydateMapDetail? {
        guard kind == .privateMap,
              visibility == .private,
              let latitude,
              let longitude else {
            return nil
        }

        let event = PrivateEventMapItem(
            id: id,
            title: title,
            subtitle: subtitle,
            coordinate: .init(latitude: latitude, longitude: longitude),
            tintName: tintName ?? "mint",
            symbolName: symbolName ?? "house.fill"
        )

        return InterestedPlaydateMapDetail(
            event: event,
            scheduledAt: scheduledAt.flatMap(InterestedEventDTO.parseISO8601Date),
            interestedPeople: (interestedPeople ?? []).map { $0.toInterestedPersonLocation() }
        )
    }

    private static func parseISO8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

struct InterestedPersonLocationDTO: Decodable, Sendable {
    let id: UUID
    let name: String
    let locationName: String
    let latitude: Double
    let longitude: Double

    func toInterestedPersonLocation() -> InterestedPersonLocation {
        InterestedPersonLocation(
            id: id,
            name: name,
            locationName: locationName,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}
