import Foundation

struct MeetupGroup: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let location: String?
    let memberCount: Int
    let summary: String?
}

struct CreateGroupRequest: Encodable, Equatable, Sendable {
    let name: String
    let location: String
    let summary: String
    let friendUIDs: [String]

    private enum CodingKeys: String, CodingKey {
        case name
        case location
        case summary
        case friendUIDs = "friend_uids"
    }
}

struct GroupMember: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let role: String
    let joinedAt: String?
}

struct GroupDetail: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let location: String?
    let summary: String?
    let ownerUID: String?
    let createdAt: String?
    var members: [GroupMember]

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
            id: "1",
            name: "Coffee Chat Crew",
            location: "Cupertino",
            summary: "Weekly casual meetups for coffee, product chats, and meeting new people.",
            ownerUID: "owner-1",
            createdAt: "2026-05-03T13:31:30.463Z",
            members: [
                GroupMember(id: "amy-chen", name: "Amy Chen", role: "Organizer", joinedAt: nil),
                GroupMember(id: "brian-lee", name: "Brian Lee", role: "Member", joinedAt: nil),
                GroupMember(id: "sofia-wang", name: "Sofia Wang", role: "Member", joinedAt: nil)
            ]
        ),
        GroupDetail(
            id: "2",
            name: "SwiftUI Builders",
            location: "San Jose",
            summary: "A small builder community for iOS developers shipping SwiftUI side projects.",
            ownerUID: "owner-2",
            createdAt: "2026-05-03T13:31:30.463Z",
            members: [
                GroupMember(id: "mia-park", name: "Mia Park", role: "Organizer", joinedAt: nil),
                GroupMember(id: "noah-patel", name: "Noah Patel", role: "Member", joinedAt: nil),
                GroupMember(id: "emma-davis", name: "Emma Davis", role: "Member", joinedAt: nil),
                GroupMember(id: "lucas-kim", name: "Lucas Kim", role: "Member", joinedAt: nil)
            ]
        ),
        GroupDetail(
            id: "3",
            name: "Weekend Hikers",
            location: "Palo Alto",
            summary: "Plan easy weekend hikes and explore Bay Area trails together.",
            ownerUID: "owner-3",
            createdAt: "2026-05-03T13:31:30.463Z",
            members: [
                GroupMember(id: "olivia-brown", name: "Olivia Brown", role: "Organizer", joinedAt: nil),
                GroupMember(id: "ethan-nguyen", name: "Ethan Nguyen", role: "Member", joinedAt: nil),
                GroupMember(id: "chloe-garcia", name: "Chloe Garcia", role: "Member", joinedAt: nil)
            ]
        )
    ]
}
