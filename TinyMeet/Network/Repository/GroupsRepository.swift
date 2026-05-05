import Foundation

protocol GroupsRepositoryProtocol: Sendable {
    func fetchGroups() async throws -> [MeetupGroup]
    func createGroup(_ request: CreateGroupRequest) async throws
    func fetchGroupDetail(groupID: String) async throws -> GroupDetail
    func deleteGroup(groupID: String) async throws
    func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail
    func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws
    func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool
}

struct GroupsRepository: GroupsRepositoryProtocol, Sendable {
    private let networkManager: NetworkManaging
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchGroups() async throws -> [MeetupGroup] {
        let request = try GroupUrlRequest.list.asURLRequest()
        let response: GroupListResponse = try await networkManager.perform(request)
        return response.groups.map { group in
            MeetupGroup(
                id: group.id,
                name: group.name,
                location: group.location,
                memberCount: 0,
                summary: group.summary
            )
        }
    }

    func createGroup(_ request: CreateGroupRequest) async throws {
        let request = try GroupUrlRequest.create(request).asURLRequest()
        let _: EmptyGroupResponse = try await networkManager.perform(request)
    }

    func fetchGroupDetail(groupID: String) async throws -> GroupDetail {
        let request = try GroupUrlRequest.detail(groupID: groupID).asURLRequest()
        let response: GroupDetailResponseDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
    }

    func deleteGroup(groupID: String) async throws {
        let request = try GroupUrlRequest.deleteGroup(groupID: groupID).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(request)
    }

    func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GroupsRepositoryError.invalidMemberName
        }

        let request = try GroupUrlRequest.addMember(groupID: groupDetail.id, name: trimmedName).asURLRequest()
        let response: MockGroupDetailDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
    }

    func inviteUserProfile(_ userProfile: UserProfile, toGroupID groupID: String) async throws {
        let groupDetail = try await fetchGroupDetail(groupID: groupID)

        guard groupDetail.members.contains(where: {
            $0.id.caseInsensitiveCompare(userProfile.id) == .orderedSame
                || $0.name.caseInsensitiveCompare(userProfile.username) == .orderedSame
        }) == false else {
            throw GroupsRepositoryError.memberAlreadyExists
        }

        let request = try GroupUrlRequest.inviteUserProfile(groupID: groupID, inviteeUID: userProfile.id).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(request)
    }

    func deleteMember(memberID: String, from groupDetail: GroupDetail) async throws -> Bool {
        guard groupDetail.members.contains(where: { $0.id == memberID }) else {
            throw GroupsRepositoryError.memberNotFound
        }

        let request = try GroupUrlRequest.deleteMember(groupID: groupDetail.id, memberID: memberID).asURLRequest()
        let response: GeneralResponse = try await networkManager.perform(
            request
        )
        return response.success ?? true
    }

    private func loadMockGroups() throws -> [GroupDetail] {
        let response: MockGroupsResponse = try loadMockResponse(named: "mock_groups")
        return response.items.map { $0.toGroupDetail() }
    }

    private func loadMockGroupDetails() throws -> [GroupDetail] {
        let response: MockGroupsResponse = try loadMockResponse(named: "mock_group_details")
        return response.items.map { $0.toGroupDetail() }
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw GroupsRepositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GroupsRepositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum GroupsRepositoryError: LocalizedError {
    case groupNotFound
    case memberNotFound
    case invalidMemberName
    case memberAlreadyExists
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "We couldn't find that group."
        case .memberNotFound:
            return "We couldn't find that member."
        case .invalidMemberName:
            return "Enter a valid member name."
        case .memberAlreadyExists:
            return "That profile is already in the group."
        case .missingMockResource(let name):
            return "Missing mock groups JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock groups JSON resource \(name).json (\(underlying.localizedDescription))"
        }
    }
}

private struct GroupListResponse: Decodable, Sendable {
    let groups: [GroupListItemDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case groups
        case nextCursor = "next_cursor"
    }
}

private struct EmptyGroupResponse: Decodable, Sendable {}

private struct GroupListItemDTO: Decodable, Sendable {
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

private struct GroupDetailResponseDTO: Decodable, Sendable {
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

private struct GroupDetailMemberDTO: Decodable, Sendable {
    let groupID: String
    let uid: String
    let role: String
    let joinedAt: String

    private enum CodingKeys: String, CodingKey {
        case groupID = "group_id"
        case uid
        case role
        case joinedAt = "joined_at"
    }

    func toGroupMember() -> GroupMember {
        GroupMember(
            id: uid,
            name: uid,
            role: role,
            joinedAt: joinedAt
        )
    }
}

private struct MockGroupsResponse: Decodable, Sendable {
    let items: [MockGroupDetailDTO]
}

private struct MockGroupDetailDTO: Decodable, Sendable {
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

private struct MockGroupMemberDTO: Decodable, Sendable {
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
