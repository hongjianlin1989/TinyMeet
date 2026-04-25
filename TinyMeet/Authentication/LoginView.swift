import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = LoginViewModel()
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.badge.key")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("login.title")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("login.message")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("login.identifier.label")
                            .font(.headline)

                        TextField("login.identifier.placeholder", text: $viewModel.identifier)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("login.password.label")
                            .font(.headline)

                        SecureField("login.password.placeholder", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(12)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                VStack(spacing: 12) {
                    Button("login.submit") {
                        viewModel.loginTapped()
                        appSession.logIn()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                  //  .disabled(!viewModel.isFormValid)

                    Button("login.signup") {
                        viewModel.signUpTapped()
                        isShowingSignUp = true
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

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
                                    .frame(width: 24, height: 24)

                                Text("G")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
                            }

                            if viewModel.isGoogleSigningIn {
                                ProgressView()
                                    .controlSize(.small)
                            }

                            Text(viewModel.isGoogleSigningIn ? "Signing in with Google..." : "Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .disabled(viewModel.isGoogleSigningIn)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("login.navigation.title")
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
}

#Preview {
    LoginView()
        .environmentObject(AppSession())
}
