import CoreLocation
import Foundation

protocol PrivatePlaydateRepositoryProtocol: Sendable {
    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem]
}

struct PrivatePlaydateRepository: PrivatePlaydateRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(
        networkManager: NetworkManaging? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchPrivatePlaydates() async throws -> [PrivateEventMapItem] {
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
