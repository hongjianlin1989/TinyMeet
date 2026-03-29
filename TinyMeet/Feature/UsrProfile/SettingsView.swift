import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("settings.section.language") {
                NavigationLink {
                    languageSelectionList
                } label: {
                    HStack {
                        Text("settings.language.label")
                        Spacer()
                        Text(viewModel.selectedLanguageOption.displayNameKey)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("settings.section.security") {
                Button("settings.password.reset") {
                    viewModel.resetPasswordTapped()
                }

                if let passwordResetMessage = viewModel.passwordResetMessage {
                    Text(passwordResetMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("settings.logout", role: .destructive) {
                    appSession.logOut()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("settings.navigation.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.updateSelectedLanguageCode(appSession.selectedLanguageCode)
        }
    }

    private var languageSelectionList: some View {
        List {
            ForEach(viewModel.availableLanguages) { language in
                Button {
                    viewModel.updateSelectedLanguageCode(language.code)
                    appSession.updateLanguageCode(language.code)
                } label: {
                    HStack {
                        Text(language.displayNameKey)
                            .foregroundStyle(.primary)

                        Spacer()

                        if language.code == viewModel.selectedLanguageCode {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(TinyMeetTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .scrollContentBackground(.hidden)
        .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("settings.language.label")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel.makeDefault())
            .environmentObject(AppSession(isLoggedIn: true, selectedLanguageCode: "en"))
    }
}
