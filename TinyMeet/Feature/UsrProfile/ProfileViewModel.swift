import Combine
import Foundation

struct InviteSharePayload: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let url: URL

    var activityItems: [Any] {
        [message, url]
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var inviteSharePayload: InviteSharePayload?
    @Published var isShowingCreateEvent = false
    @Published var isShowingLogin = false
    @Published var isShowingSettings = false

    private let profileRespository: ProfileRespositoryProtocol

    init(profileRespository: ProfileRespositoryProtocol) {
        self.profileRespository = profileRespository
    }

    static func makeDefault() -> ProfileViewModel {
        ProfileViewModel(profileRespository: ProfileRespository())
    }

    func fetchUserProfile(isLoggedIn: Bool) async {
        guard isLoggedIn else {
            userProfile = nil
            errorMessage = nil
            isLoading = false
            return
        }

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

    func inviteFriendsTapped() {
        inviteSharePayload = InviteSharePayload(
            title: "Invite Your Friend",
            message: inviteMessage,
            url: inviteDeepLinkURL
        )
    }

    func clearInviteSharePayload() {
        inviteSharePayload = nil
    }

    func createEventTapped() {
        isShowingCreateEvent = true
    }

    func loginTapped() {
        isShowingLogin = true
    }

    func settingsTapped() {
        isShowingSettings = true
    }

    func handleLogout() {
        isShowingSettings = false
        userProfile = nil
        errorMessage = nil
    }

    private var inviteMessage: String {
        let inviterName = userProfile?.username ?? "a friend"
        return "\(inviterName) invited you to join TinyMeet so you can plan playdates together. Open your invite here: \(inviteDeepLinkURL.absoluteString)"
    }

    private var inviteDeepLinkURL: URL {
        var components = URLComponents()
        components.scheme = "tinymeet"
        components.host = "invite"

        if let inviterID = userProfile?.id {
            components.queryItems = [
                URLQueryItem(name: "referrer", value: String(inviterID))
            ]
        }

        return components.url ?? URL(string: "https://tinymeet.app/invite")!
    }
}
