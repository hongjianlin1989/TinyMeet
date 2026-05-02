import Testing
@testable import TinyMeet
import Foundation

struct LoginViewModelTests {
    actor EmailRecorder {
        private(set) var email: String?

        func record(_ email: String) {
            self.email = email
        }
    }

    actor CallCounter {
        private(set) var count = 0

        func increment() {
            count += 1
        }
    }

    struct MockAuthenticationRepository: AuthenticationRepositoryProtocol {
        let googleHandler: @Sendable () async throws -> Void
        let emailLinkHandler: @Sendable (String) async throws -> Void
        let developmentEmailHandler: @Sendable (String) async throws -> DevelopmentAuthenticationSession

        init(
            googleHandler: @escaping @Sendable () async throws -> Void = {},
            emailLinkHandler: @escaping @Sendable (String) async throws -> Void = { _ in },
            developmentEmailHandler: @escaping @Sendable (String) async throws -> DevelopmentAuthenticationSession = { email in
                DevelopmentAuthenticationSession(
                    token: "token-for-\(email)",
                    uid: "uid-for-\(email)",
                    email: email,
                    displayName: email,
                    expiresIn: "7 days"
                )
            }
        ) {
            self.googleHandler = googleHandler
            self.emailLinkHandler = emailLinkHandler
            self.developmentEmailHandler = developmentEmailHandler
        }

        @MainActor
        func signInWithGoogle() async throws {
            try await googleHandler()
        }

        func sendSignInLink(to email: String) async throws {
            try await emailLinkHandler(email)
        }

        func signInWithDevelopmentEmail(_ email: String) async throws -> DevelopmentAuthenticationSession {
            try await developmentEmailHandler(email)
        }
    }

    @MainActor
    @Test func sendSignInLinkUsesTrimmedEmailAndStoresSuccessMessage() async throws {
        let emailRecorder = EmailRecorder()
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(emailLinkHandler: { email in
                await emailRecorder.record(email)
            })
        )

        viewModel.emailLinkEmail = "  parent@example.com  "

        let didSend = await viewModel.sendSignInLinkTapped()

        #expect(didSend)
        #expect(await emailRecorder.email == "parent@example.com")
        #expect(viewModel.signInLinkMessage == "We sent a sign-in link to parent@example.com.")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSendingSignInLink == false)
    }

    @MainActor
    @Test func sendSignInLinkRejectsInvalidEmailWithoutCallingRepository() async throws {
        let callCounter = CallCounter()
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(emailLinkHandler: { _ in
                await callCounter.increment()
            })
        )

        viewModel.emailLinkEmail = "not-an-email"

        let didSend = await viewModel.sendSignInLinkTapped()

        #expect(didSend == false)
        #expect(await callCounter.count == 0)
        #expect(viewModel.errorMessage == AuthenticationError.invalidEmail.localizedDescription)
        #expect(viewModel.signInLinkMessage == nil)
    }

    @MainActor
    @Test func developmentEmailSignInUsesTrimmedEmail() async throws {
        let emailRecorder = EmailRecorder()
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(developmentEmailHandler: { email in
                await emailRecorder.record(email)
                return DevelopmentAuthenticationSession(
                    token: "dev-token",
                    uid: "dev-uid",
                    email: email,
                    displayName: "Dev User",
                    expiresIn: "7 days"
                )
            })
        )

        viewModel.developmentEmail = "  dev@example.com  "

        let didSignIn = await viewModel.signInWithDevelopmentEmailTapped()

        #expect(didSignIn)
        #expect(await emailRecorder.email == "dev@example.com")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.signInLinkMessage == nil)
        #expect(viewModel.isDevelopmentSigningIn == false)
    }

    @MainActor
    @Test func developmentEmailSignInRejectsInvalidEmailWithoutCallingRepository() async throws {
        let callCounter = CallCounter()
        let viewModel = LoginViewModel(
            authenticationRepository: MockAuthenticationRepository(developmentEmailHandler: { email in
                await callCounter.increment()
                return DevelopmentAuthenticationSession(
                    token: "dev-token",
                    uid: "dev-uid",
                    email: email,
                    displayName: "Dev User",
                    expiresIn: "7 days"
                )
            })
        )

        viewModel.developmentEmail = "not-an-email"

        let didSignIn = await viewModel.signInWithDevelopmentEmailTapped()

        #expect(didSignIn == false)
        #expect(await callCounter.count == 0)
        #expect(viewModel.errorMessage == AuthenticationError.invalidEmail.localizedDescription)
        #expect(viewModel.isDevelopmentSigningIn == false)
    }
}
