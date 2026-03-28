import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
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
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(!viewModel.isFormValid)

                    Button("login.signup") {
                        viewModel.signUpTapped()
                        isShowingSignUp = true
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
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
}
