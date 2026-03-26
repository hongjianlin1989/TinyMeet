import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let profileRespository: ProfileRespositoryProtocol

    init(profileRespository: ProfileRespositoryProtocol) {
        self.profileRespository = profileRespository
    }

    static func makeDefault() -> ProfileViewModel {
        ProfileViewModel(profileRespository: ProfileRespository())
    }

    func fetchUserProfile() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            userProfile = try await profileRespository.fetchUserProfile()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
