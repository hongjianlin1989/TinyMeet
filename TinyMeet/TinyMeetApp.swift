//
//  TinyMeetApp.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/25/26.
//

import SwiftUI
import CoreData

@main
struct TinyMeetApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appSession = AppSession()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(TinyMeetTheme.accent)
                .environmentObject(appSession)
                .environment(\.locale, appSession.locale)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
