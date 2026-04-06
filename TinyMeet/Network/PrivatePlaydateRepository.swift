import CoreLocation
import Foundation

protocol PrivatePlaydateRepositoryProtocol: Sendable {
    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem]
}

struct PrivatePlaydateRepository: PrivatePlaydateRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(
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

    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            let response: PrivatePlaydateListResponse = try loadMockResponse(named: "private_playdates")
            return response.items.map { $0.toMapItem() }
        }

        let request = PrivatePlaydateUrlRequest.list.asURLRequest()
        let response: PrivatePlaydateListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toMapItem() }
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw PrivatePlaydateRepositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PrivatePlaydateRepositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum PrivatePlaydateRepositoryError: LocalizedError {
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingMockResource(let name):
            return "Missing mock private playdates JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock private playdates JSON resource \(name).json (\(underlying.localizedDescription))"
        }
    }
}

struct PrivatePlaydateListResponse: Decodable, Sendable {
    let items: [PrivatePlaydateDTO]
}

struct PrivatePlaydateDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let tintName: String
    let symbolName: String

    func toMapItem() -> PrivateEventMapItem {
        PrivateEventMapItem(
            id: id,
            title: title,
            subtitle: subtitle,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            tintName: tintName,
            symbolName: symbolName
        )
    }
}
