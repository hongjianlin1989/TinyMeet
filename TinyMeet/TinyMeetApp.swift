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
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
