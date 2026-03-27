import Foundation

struct MeetupGroup: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let location: String?
    let memberCount: Int
    let summary: String?
}

extension MeetupGroup {
    static let mockGroups: [MeetupGroup] = [
        MeetupGroup(
            id: 1,
            name: "Coffee Chat Crew",
            location: "Cupertino",
            memberCount: 18,
            summary: "Weekly casual meetups for coffee, product chats, and meeting new people."
        ),
        MeetupGroup(
            id: 2,
            name: "SwiftUI Builders",
            location: "San Jose",
            memberCount: 32,
            summary: "A small builder community for iOS developers shipping SwiftUI side projects."
        ),
        MeetupGroup(
            id: 3,
            name: "Weekend Hikers",
            location: "Palo Alto",
            memberCount: 24,
            summary: "Plan easy weekend hikes and explore Bay Area trails together."
        )
    ]
}
