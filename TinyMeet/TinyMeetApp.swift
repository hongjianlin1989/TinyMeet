//
//  TinyMeetApp.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/25/26.
//

import CoreData
import GoogleSignIn
import SwiftUI

@main
struct TinyMeetApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appSession = AppSession()
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private let authRepository: AuthenticationRepositoryProtocol = FirebaseAuthenticationRepository()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(TinyMeetTheme.accent)
                .environmentObject(appSession)
                .environmentObject(deepLinkHandler)
                .environment(\.locale, appSession.locale)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }

                    _ = deepLinkHandler.handle(url)
                }
                .onChange(of: deepLinkHandler.activeDestination) { _, destination in
                    if case .emailSignIn(let email, let link) = destination {
                        handleEmailSignIn(email: email, link: link)
                    }
                }
                .sheet(isPresented: Binding(
                    get: { deepLinkHandler.isShowingLogin },
                    set: { isPresented in
                        if !isPresented {
                            deepLinkHandler.dismissPresentedDestination()
                        }
                    }
                )) {
                    LoginView()
                        .environmentObject(appSession)
                }
                .task {
                    await appSession.bootstrapAuthentication()
                }
        }
    }

    // MARK: - Email magic-link sign-in

    private func handleEmailSignIn(email: String, link: String) {
        Task {
            do {
                let token = try await authRepository.completeEmailLinkSignIn(email: email, link: link)
                try await callBackendLogin(token: token)
                appSession.logIn()
            } catch {
                // Sign-in failed — reset destination so the user can try again
                print("[TinyMeetApp] Email sign-in failed: \(error.localizedDescription)")
            }
            deepLinkHandler.dismissPresentedDestination()
        }
    }

    /// Exchange the Firebase ID token for a TinyMeet profile via POST /api/v1/auth/login.
    private func callBackendLogin(token: String) async throws {
        guard let url = URL(string: "https://tinymeet-api.licongchen.org/api/v1/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
