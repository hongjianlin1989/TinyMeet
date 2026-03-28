import Combine
import Foundation

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    static func makeDefault() -> SignUpViewModel {
        SignUpViewModel()
    }

    var isFormValid: Bool {
        !trimmedName.isEmpty
            && isEmailValid
            && password.count >= 8
            && password == confirmPassword
    }

    func signUp() async -> Bool {
        guard !isLoading else { return false }

        errorMessage = nil
        successMessage = nil

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter your name."
            return false
        }

        guard isEmailValid else {
            errorMessage = "Please enter a valid email address."
            return false
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(for: .milliseconds(600))

        successMessage = "Account created successfully."
        return true
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEmailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }
}
