import Foundation

protocol GroupsRepositoryProtocol: Sendable {
    func fetchGroups() async throws -> [MeetupGroup]
}

struct GroupsRepository: GroupsRepositoryProtocol, Sendable {
    private let shouldUseMockData: Bool

    init(shouldUseMockData: Bool = true) {
        self.shouldUseMockData = shouldUseMockData
    }

    func fetchGroups() async throws -> [MeetupGroup] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return MeetupGroup.mockGroups
        }

        return []
    }
}
