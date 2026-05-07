import Foundation

struct GroupListResponse: Decodable, Sendable {
    let groups: [GroupListItemDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case groups
        case nextCursor = "next_cursor"
    }
}

struct EmptyGroupResponse: Decodable, Sendable {}

struct GroupListItemDTO: Decodable, Sendable {
    let id: String
    let name: String
    let location: String?
    let summary: String?
    let ownerUID: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case summary
        case ownerUID = "owner_uid"
        case createdAt = "created_at"
    }
}

struct GroupDetailResponseDTO: Decodable, Sendable {
    let id: String
    let name: String
    let location: String?
    let summary: String?
    let ownerUID: String
    let createdAt: String
    let members: [GroupDetailMemberDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case summary
        case ownerUID = "owner_uid"
        case createdAt = "created_at"
        case members
    }

    func toGroupDetail() -> GroupDetail {
        GroupDetail(
            id: id,
            name: name,
            location: location,
            summary: summary,
            ownerUID: ownerUID,
            createdAt: createdAt,
            members: members.map { $0.toGroupMember() }
        )
    }
}

struct GroupInviteResponseDTO: Decodable, Sendable {
    let id: String
    let groupID: String
    let groupName: String
    let groupSummary: String?
    let ownerUID: String?
    let createdAt: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedGroup = try container.decodeIfPresent(GroupInviteNestedGroupDTO.self, forKey: .group)
        let decodedGroupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedGroupSummary = try container.decodeIfPresent(String.self, forKey: .groupSummary)
        let decodedSummary = try container.decodeIfPresent(String.self, forKey: .summary)
        let decodedOwnerUID = try container.decodeIfPresent(String.self, forKey: .ownerUID)

        id = try container.decodeFlexibleString(forKey: .id)
        groupID = container.decodeFlexibleStringIfPresent(forKey: .groupID) ?? nestedGroup?.id ?? id
        groupName = decodedGroupName ?? decodedName ?? nestedGroup?.name ?? groupID
        groupSummary = decodedGroupSummary ?? decodedSummary ?? nestedGroup?.summary
        ownerUID = decodedOwnerUID ?? nestedGroup?.ownerUID
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case groupID = "group_id"
        case groupName = "group_name"
        case name
        case groupSummary = "group_summary"
        case summary
        case ownerUID = "owner_uid"
        case createdAt = "created_at"
        case group
    }

    func toGroupInvite() -> GroupInvite {
        GroupInvite(
            id: id,
            groupID: groupID,
            groupName: groupName,
            groupSummary: groupSummary,
            ownerUID: ownerUID,
            createdAt: createdAt
        )
    }
}

struct GroupInviteNestedGroupDTO: Decodable, Sendable {
    let id: String
    let name: String?
    let summary: String?
    let ownerUID: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        ownerUID = try container.decodeIfPresent(String.self, forKey: .ownerUID)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case summary
        case ownerUID = "owner_uid"
    }
}

struct GroupDetailMemberDTO: Decodable, Sendable {
    let groupID: String
    let uid: String
    let name: String?
    let role: String
    let joinedAt: String

    private enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case uid
        case name = "display_name"
        case role
        case joinedAt = "joined_at"
    }

    func toGroupMember() -> GroupMember {
        GroupMember(
            id: uid,
            name: name ?? uid,
            role: role,
            joinedAt: joinedAt
        )
    }
}

struct MockGroupsResponse: Decodable, Sendable {
    let items: [MockGroupDetailDTO]
}

struct MockGroupDetailDTO: Decodable, Sendable {
    let id: String
    let name: String
    let location: String?
    let summary: String?
    let members: [MockGroupMemberDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Expected a string or int group id.")
        }

        name = try container.decode(String.self, forKey: .name)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        members = try container.decode([MockGroupMemberDTO].self, forKey: .members)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case summary
        case members
    }

    func toGroupDetail() -> GroupDetail {
        GroupDetail(
            id: id,
            name: name,
            location: location,
            summary: summary,
            ownerUID: nil,
            createdAt: nil,
            members: members.map { $0.toGroupMember() }
        )
    }
}

struct MockGroupMemberDTO: Decodable, Sendable {
    let id: String
    let name: String
    let role: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Expected a string or int member id.")
        }

        name = try container.decode(String.self, forKey: .name)
        role = try container.decode(String.self, forKey: .role)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case role
    }

    func toGroupMember() -> GroupMember {
        GroupMember(id: id, name: name, role: role, joinedAt: nil)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected a string or int value."
        )
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) -> String? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        return nil
    }
}
