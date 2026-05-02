import Testing
@testable import TinyMeet
import Foundation

struct LoginViewModelTests {
    struct MockAuthenticationRepository: AuthenticationRepositoryProtocol {
        let googleHandler: @Sendable () async throws -> Void
        let emailLinkHandler: @Sendable (String) async throws -> Void

        init(
            googleHandler: @escaping @Sendable () async throws -> Void = {},
            emailLinkHandler: @escaping @Sendable (String) async throws -> Void = { _ in }
        ) {
            self.googleHandler = googleHandler
            self.emailLinkHandler = emailLinkHandler
        }

        @MainActor
        func signInWithGoogle() async throws {
            try await googleHandler()
        }

        func sendSignInLink(to email: String) async throws {
            try await emailLinkHandler(email)
        }
    }

    @MainActor
    @Test func sendSignInLinkUsesTrimmedEmailAndStoresSuccessMessage() async throws {
        var receivedEmail: String?
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(emailLinkHandler: { email in
                receivedEmail = email
            })
        )

        viewModel.emailLinkEmail = "  parent@example.com  "

        let didSend = await viewModel.sendSignInLinkTapped()

        #expect(didSend)
        #expect(receivedEmail == "parent@example.com")
        #expect(viewModel.signInLinkMessage == "We sent a sign-in link to parent@example.com.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSendingSignInLink == false)
    }

    @MainActor
    @Test func sendSignInLinkRejectsInvalidEmailWithoutCallingRepository() async throws {
        var repositoryCallCount = 0
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(emailLinkHandler: { _ in
                repositoryCallCount += 1
            })
        )

        viewModel.emailLinkEmail = "not-an-email"

        let didSend = await viewModel.sendSignInLinkTapped()

        #expect(didSend == false)
        #expect(repositoryCallCount == 0)
        #expect(viewModel.errorMessage == AuthenticationError.invalidEmail.localizedDescription)
        #expect(viewModel.signInLinkMessage == nil)
    }
}
