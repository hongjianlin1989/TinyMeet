import SwiftUI

struct AuthToolbarButton: View {
    @EnvironmentObject private var appSession: AppSession
    @State private var isShowingLogin = false
    @State private var isShowingSettings = false

    var body: some View {
        Button {
            if appSession.isLoggedIn {
                isShowingSettings = true
            } else {
                isShowingLogin = true
            }
        } label: {
            Label(buttonTitle, systemImage: buttonSystemImage)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(TinyMeetAuthToolbarButtonStyle())
        .navigationDestination(isPresented: $isShowingSettings) {
            SettingsView(viewModel: SettingsViewModel.makeDefault())
        }
        .sheet(isPresented: $isShowingLogin) {
            LoginView()
        }
    }

    private var buttonTitle: LocalizedStringKey {
        appSession.isLoggedIn ? "settings.navigation.title" : "login.submit"
    }

    private var buttonSystemImage: String {
        appSession.isLoggedIn ? "gearshape.fill" : "person.crop.circle.badge.plus"
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
    }
}
