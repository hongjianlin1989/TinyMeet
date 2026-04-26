import Foundation

protocol LocationRepositoryProtocol: Sendable {
    func updateCurrentLocation(latitude: Double, longitude: Double) async throws
}

struct LocationRepository: LocationRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        shouldUseMockData: Bool = true
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
    }

    func updateCurrentLocation(latitude: Double, longitude: Double) async throws {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(100))
            return
        }

        let request = try LocationUrlRequest.updateCurrentLocation(latitude: latitude, longitude: longitude).asURLRequest()
        let _: UpdateCurrentLocationResponse = try await networkManager.perform(request)
    }
}

private struct UpdateCurrentLocationResponse: Decodable, Sendable {
    let success: Bool?
}
