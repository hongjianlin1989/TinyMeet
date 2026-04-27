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
        }
    }
}
