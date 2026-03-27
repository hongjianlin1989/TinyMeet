import Combine
import Foundation

@MainActor
final class GroupsViewModel: ObservableObject {
    @Published private(set) var groups: [MeetupGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let groupsRepository: GroupsRepositoryProtocol

    init(groupsRepository: GroupsRepositoryProtocol) {
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> GroupsViewModel {
        GroupsViewModel(groupsRepository: GroupsRepository())
    }

    func fetchGroups() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            groups = try await groupsRepository.fetchGroups()
        } catch {
            groups = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
