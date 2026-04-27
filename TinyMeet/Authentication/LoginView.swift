import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = LoginViewModel()
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    Button("login.submit") {
                        viewModel.loginTapped()
                        appSession.logIn()
                        dismiss()
                    }
                    .buttonStyle(TinyMeetPrimaryButtonStyle())
                  //  passwordLoginCard
                 //   dividerLabel
                    signInLinkCard
                    googleButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .tinyMeetPageBackground()
            .navigationTitle("login.navigation.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("login.close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView(viewModel: SignUpViewModel.makeDefault())
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TinyMeetTheme.heroGradient)
                    .frame(width: 94, height: 94)
                    .shadow(color: TinyMeetTheme.shadow.opacity(0.28), radius: 18, x: 0, y: 10)

                Image(systemName: "person.crop.circle.badge.key")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("login.title")
                    .font(.title2.weight(.bold))

                Text("login.message")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }

    private var passwordLoginCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Use your account")
                .font(.headline.weight(.bold))

            VStack(alignment: .leading, spacing: 14) {
                field(title: String(localized: "login.identifier.label")) {
                    TextField("login.identifier.placeholder", text: $viewModel.identifier)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                }

                field(title: String(localized: "login.password.label")) {
                    SecureField("login.password.placeholder", text: $viewModel.password)
                        .textContentType(.password)
                }
            }

            VStack(spacing: 12) {
                Button("login.submit") {
                    viewModel.loginTapped()
                    appSession.logIn()
                    dismiss()
                }
                .buttonStyle(TinyMeetPrimaryButtonStyle())

                Button("login.signup") {
                    viewModel.signUpTapped()
                    isShowingSignUp = true
                }
                .buttonStyle(TinyMeetSecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
        .tinyMeetCardStyle()
    }

    private var dividerLabel: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(TinyMeetTheme.accent.opacity(0.18))
                .frame(height: 1)

            Text("or")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(TinyMeetTheme.accent.opacity(0.18))
                .frame(height: 1)
        }
        .padding(.horizontal, 6)
    }

    private var signInLinkCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick sign in")
                .font(.headline.weight(.bold))

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(TinyMeetTheme.accent)

                    TextField("you@example.com", text: $viewModel.emailLinkEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(TinyMeetTheme.sky)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.2)
                }

                Button {
                    Task {
                        _ = await viewModel.sendSignInLinkTapped()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isSendingSignInLink {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }

                        Text(viewModel.isSendingSignInLink ? "Sending sign-in link..." : "Send sign-in link")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(TinyMeetPrimaryButtonStyle())
                .opacity(viewModel.canSendSignInLink && !viewModel.isSendingSignInLink ? 1 : 0.42)
                .disabled(!viewModel.canSendSignInLink || viewModel.isSendingSignInLink)
            }

            if let signInLinkMessage = viewModel.signInLinkMessage {
                feedbackCard(message: signInLinkMessage, color: TinyMeetTheme.mint)
            }

            if let errorMessage = viewModel.errorMessage {
                feedbackCard(message: errorMessage, color: TinyMeetTheme.accent)
            }
        }
        .padding(22)
        .tinyMeetCardStyle()
    }

    private var googleButton: some View {
        Button {
            Task {
                let didSignIn = await viewModel.signInWithGoogleTapped()
                if didSignIn {
                    appSession.logIn()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)

                    Text("G")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
                }

                if viewModel.isGoogleSigningIn {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }

                Text(viewModel.isGoogleSigningIn ? "Signing in with Google..." : "Continue with Google")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(viewModel.isGoogleSigningIn || viewModel.isSendingSignInLink)
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                }
        }
    }

    private func feedbackCard(message: String, color: Color) -> some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    LoginView()
        .environmentObject(AppSession())
}
