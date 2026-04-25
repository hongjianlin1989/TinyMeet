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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(TinyMeetTheme.accent)
                .environmentObject(appSession)
                .environment(\.locale, appSession.locale)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
