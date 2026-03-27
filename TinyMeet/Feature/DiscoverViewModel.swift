import Combine
import Foundation

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var profiles: [UserProfile] = []
    @Published private(set) var groups: [MeetupGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let profileRespository: ProfileRespositoryProtocol
    private let groupsRepository: GroupsRepositoryProtocol

    init(
        profileRespository: ProfileRespositoryProtocol,
        groupsRepository: GroupsRepositoryProtocol
    ) {
        self.profileRespository = profileRespository
        self.groupsRepository = groupsRepository
    }

    static func makeDefault() -> DiscoverViewModel {
        DiscoverViewModel(
            profileRespository: ProfileRespository(),
            groupsRepository: GroupsRepository()
        )
    }

    var hasActiveQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadGroups() async {
        do {
            groups = try await groupsRepository.fetchGroups()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchProfiles() async {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            profiles = []
            errorMessage = nil
            successMessage = nil
            return
        }

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        do {
            profiles = try await profileRespository.searchUserProfiles(query: trimmedQuery)
        } catch {
            profiles = []
            errorMessage = error.localizedDescription
        }
    }

    func addProfileToGroup(_ profile: UserProfile, groupID: Int) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        defer { isLoading = false }

        do {
            let updatedGroup = try await groupsRepository.addUserProfile(profile, toGroupID: groupID)
            successMessage = "Added @\(profile.username) to \(updatedGroup.name)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
