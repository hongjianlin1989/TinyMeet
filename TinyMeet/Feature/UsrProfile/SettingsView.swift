import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Language") {
                Picker("Language Model", selection: $viewModel.selectedLanguage) {
                    ForEach(viewModel.availableLanguages, id: \.self) { language in
                        Text(language)
                            .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Security") {
                Button("Reset Password") {
                    viewModel.resetPasswordTapped()
                }

                if let passwordResetMessage = viewModel.passwordResetMessage {
                    Text(passwordResetMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Log Out", role: .destructive) {
                    appSession.logOut()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel.makeDefault())
            .environmentObject(AppSession(isLoggedIn: true))
    }
}
