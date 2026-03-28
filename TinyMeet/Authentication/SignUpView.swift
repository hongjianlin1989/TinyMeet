import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SignUpViewModel

    init(viewModel: SignUpViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("Create account")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Join TinyMeet and start connecting with other families nearby.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        field(title: "Name") {
                            TextField("Your name", text: $viewModel.name)
                                .textInputAutocapitalization(.words)
                                .textContentType(.name)
                        }

                        field(title: "Email") {
                            TextField("name@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                        }

                        field(title: "Password") {
                            SecureField("At least 8 characters", text: $viewModel.password)
                                .textContentType(.newPassword)
                        }

                        field(title: "Confirm Password") {
                            SecureField("Re-enter your password", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        feedbackCard(message: errorMessage, color: .red)
                    }

                    if let successMessage = viewModel.successMessage {
                        feedbackCard(message: successMessage, color: .green)
                    }

                    Button {
                        Task {
                            let didSucceed = await viewModel.signUp()
                            if didSucceed {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)

                    Spacer(minLength: 12)
                }
                .padding()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func field<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content()
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func feedbackCard(message: String, color: Color) -> some View {
        Text(message)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(color)
    }
}

#Preview {
    SignUpView(viewModel: SignUpViewModel.makeDefault())
}
