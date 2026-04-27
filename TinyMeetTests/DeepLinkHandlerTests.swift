import Foundation
import Testing
@testable import TinyMeet

struct DeepLinkHandlerTests {
    @Test func parsesLoginDeepLinks() throws {
        let customSchemeURL = try #require(URL(string: "tinymeet://login"))
        let customPathURL = try #require(URL(string: "tinymeet:///login"))
        let webURL = try #require(URL(string: "https://tinymeet.app/login"))
        let inviteURL = try #require(URL(string: "tinymeet://invite?referrer=amy-parent"))

        #expect(DeepLinkHandler.destination(for: customSchemeURL) == .login)
        #expect(DeepLinkHandler.destination(for: customPathURL) == .login)
        #expect(DeepLinkHandler.destination(for: webURL) == .login)
        #expect(DeepLinkHandler.destination(for: inviteURL) == .login)
    }

    @Test func ignoresUnknownDeepLinks() throws {
        let unknownURL = try #require(URL(string: "tinymeet://profile"))
        let otherHostURL = try #require(URL(string: "https://example.com/login"))
        let inviteWithoutReferrerURL = try #require(URL(string: "tinymeet://invite"))
        let inviteWithEmptyReferrerURL = try #require(URL(string: "tinymeet://invite?referrer="))

        #expect(DeepLinkHandler.destination(for: unknownURL) == nil)
        #expect(DeepLinkHandler.destination(for: otherHostURL) == nil)
        #expect(DeepLinkHandler.destination(for: inviteWithoutReferrerURL) == nil)
        #expect(DeepLinkHandler.destination(for: inviteWithEmptyReferrerURL) == nil)
    }

    @MainActor
    @Test func handlingLoginDeepLinkPresentsLogin() throws {
        let handler = DeepLinkHandler()
        let loginURL = try #require(URL(string: "tinymeet://invite?referrer=amy-parent"))

        let didHandle = handler.handle(loginURL)

        #expect(didHandle)
        #expect(handler.activeDestination == .login)
        #expect(handler.isShowingLogin)

        handler.dismissPresentedDestination()
        #expect(handler.activeDestination == nil)
        #expect(handler.isShowingLogin == false)
    }
}
