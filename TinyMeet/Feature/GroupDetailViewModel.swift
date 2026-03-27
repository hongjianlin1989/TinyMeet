import Combine
import Foundation

@MainActor
final class GroupDetailViewModel: ObservableObject {
    @Published private(set) var groupDetail: GroupDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var newMemberName = ""

    private let groupID: Int
    private let groupsRepository: GroupsRepositoryProtocol

    init(groupID: Int, groupsRepository: GroupsRepositoryProtocol) {
        self.groupID = groupID
        self.groupsRepository = groupsRepository
    }

    static func makeDefault(groupID: Int) -> GroupDetailViewModel {
        GroupDetailViewModel(groupID: groupID, groupsRepository: GroupsRepository())
    }

    func fetchGroupDetail() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            groupDetail = try await groupsRepository.fetchGroupDetail(groupID: groupID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addMember() async {
        guard !isLoading, let groupDetail else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            self.groupDetail = try await groupsRepository.addMember(named: newMemberName, to: groupDetail)
            newMemberName = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMember(memberID: Int) async {
        guard !isLoading, let groupDetail else { return }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            self.groupDetail = try await groupsRepository.deleteMember(memberID: memberID, from: groupDetail)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
