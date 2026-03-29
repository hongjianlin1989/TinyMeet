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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(TinyMeetTheme.accent)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
