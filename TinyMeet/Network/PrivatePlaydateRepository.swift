import CoreLocation
import Foundation

protocol PrivatePlaydateRepositoryProtocol: Sendable {
    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem]
}

struct PrivatePlaydateRepository: PrivatePlaydateRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool

    init(networkManager: NetworkManaging? = nil, shouldUseMockData: Bool = true) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
    }

    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))
            return PrivateEventMapItem.mockItems
        }

        let request = PrivatePlaydateUrlRequest.list.asURLRequest()
        let response: PrivatePlaydateListResponse = try await networkManager.perform(request)
        return response.items.map { $0.toMapItem() }
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
