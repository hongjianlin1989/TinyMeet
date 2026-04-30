import SwiftUI

struct AuthToolbarButton: View {
    @EnvironmentObject private var appSession: AppSession
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @State private var friendRequestCount = 0
    @State private var isShowingSettings = false
    @State private var isShowingFriendRequests = false

    private let profileRepository: ProfileRespositoryProtocol

    init(profileRepository: ProfileRespositoryProtocol = ProfileRespository()) {
        self.profileRepository = profileRepository
    }

    var body: some View {
        Group {
            if appSession.isLoggedIn {
                HStack(spacing: 10) {
                    Button {
                        isShowingFriendRequests = true
                    } label: {
                        friendRequestsIcon
                    }
                    .buttonStyle(TinyMeetAuthToolbarButtonStyle())
                    .accessibilityLabel("Friend Requests")

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(TinyMeetAuthToolbarButtonStyle())
                    .accessibilityLabel("settings.navigation.title")
                }
            } else {
                Button {
                    deepLinkHandler.presentLogin()
                } label: {
                    Label("login.submit", systemImage: "person.crop.circle.badge.plus")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(TinyMeetAuthToolbarButtonStyle())
            }
        }
        .task(id: appSession.isLoggedIn) {
            await loadFriendRequestCountIfNeeded()
        }
        .task(id: isShowingFriendRequests) {
            if !isShowingFriendRequests {
                await loadFriendRequestCountIfNeeded()
            }
        }
        .navigationDestination(isPresented: $isShowingSettings) {
            SettingsView(viewModel: SettingsViewModel.makeDefault())
        }
        .navigationDestination(isPresented: $isShowingFriendRequests) {
            FriendRequestsView(viewModel: FriendRequestsViewModel.makeDefault())
        }
    }

    private var friendRequestsIcon: some View {
        Image(systemName: friendRequestCount > 0 ? "bell.badge.fill" : "bell.fill")
            .font(.subheadline.weight(.bold))
            .frame(width: 18, height: 18)
            .overlay(alignment: .topTrailing) {
                if friendRequestCount > 0 {
                    Text(friendRequestBadgeText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(TinyMeetTheme.accent, in: Capsule())
                        .offset(x: 12, y: -10)
                }
            }
    }

    private var friendRequestBadgeText: String {
        friendRequestCount > 9 ? "9+" : "\(friendRequestCount)"
    }

    private func loadFriendRequestCountIfNeeded() async {
        guard appSession.isLoggedIn else {
            friendRequestCount = 0
            return
        }

        do {
            let requests = try await profileRepository.fetchFriendRequests()
            friendRequestCount = requests.count
        } catch {
            friendRequestCount = 0
        }
    }
}

struct TinyMeetAuthToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(TinyMeetTheme.playfulGradient)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            }
            .shadow(
                color: TinyMeetTheme.shadow.opacity(configuration.isPressed ? 0.10 : 0.22),
                radius: configuration.isPressed ? 6 : 12,
                x: 0,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                .spring(response: 0.22, dampingFraction: 0.75),
                value: configuration.isPressed
            )
    }
}

#Preview {
    NavigationStack {
        AuthToolbarButton()
            .environmentObject(AppSession())
            .environmentObject(DeepLinkHandler())
    }
}
