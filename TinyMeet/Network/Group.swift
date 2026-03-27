import Foundation

struct MeetupGroup: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let location: String?
    let memberCount: Int
    let summary: String?
}

struct GroupMember: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let role: String
}

struct GroupDetail: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let location: String?
    let summary: String?
    let members: [GroupMember]

    var memberCount: Int { members.count }
}

extension MeetupGroup {
    nonisolated static let mockGroups: [MeetupGroup] = GroupDetail.mockDetails.map {
        MeetupGroup(
            id: $0.id,
            name: $0.name,
            location: $0.location,
            memberCount: $0.memberCount,
            summary: $0.summary
        )
    }
}

extension GroupDetail {
    nonisolated static let mockDetails: [GroupDetail] = [
        GroupDetail(
            id: 1,
            name: "Coffee Chat Crew",
            location: "Cupertino",
            summary: "Weekly casual meetups for coffee, product chats, and meeting new people.",
            members: [
                GroupMember(id: 1, name: "Amy Chen", role: "Organizer"),
                GroupMember(id: 2, name: "Brian Lee", role: "Member"),
                GroupMember(id: 3, name: "Sofia Wang", role: "Member")
            ]
        ),
        GroupDetail(
            id: 2,
            name: "SwiftUI Builders",
            location: "San Jose",
            summary: "A small builder community for iOS developers shipping SwiftUI side projects.",
            members: [
                GroupMember(id: 4, name: "Mia Park", role: "Organizer"),
                GroupMember(id: 5, name: "Noah Patel", role: "Member"),
                GroupMember(id: 6, name: "Emma Davis", role: "Member"),
                GroupMember(id: 7, name: "Lucas Kim", role: "Member")
            ]
        ),
        GroupDetail(
            id: 3,
            name: "Weekend Hikers",
            location: "Palo Alto",
            summary: "Plan easy weekend hikes and explore Bay Area trails together.",
            members: [
                GroupMember(id: 8, name: "Olivia Brown", role: "Organizer"),
                GroupMember(id: 9, name: "Ethan Nguyen", role: "Member"),
                GroupMember(id: 10, name: "Chloe Garcia", role: "Member")
            ]
        )
    ]
}
