import Foundation

protocol GroupsRepositoryProtocol: Sendable {
    nonisolated func fetchGroups() async throws -> [MeetupGroup]
    nonisolated func fetchGroupDetail(groupID: Int) async throws -> GroupDetail
    nonisolated func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail
    nonisolated func addUserProfile(_ userProfile: UserProfile, toGroupID groupID: Int) async throws -> GroupDetail
    nonisolated func deleteMember(memberID: Int, from groupDetail: GroupDetail) async throws -> GroupDetail
}

struct GroupsRepository: GroupsRepositoryProtocol, Sendable {
    private let networkManager: NetworkManaging
    private let shouldUseMockData: Bool
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        shouldUseMockData: Bool = true,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.shouldUseMockData = shouldUseMockData
        self.bundle = bundle
        self.decoder = decoder
    }

    nonisolated func fetchGroups() async throws -> [MeetupGroup] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return try loadMockGroups().map { detail in
                MeetupGroup(
                    id: detail.id,
                    name: detail.name,
                    location: detail.location,
                    memberCount: detail.memberCount,
                    summary: detail.summary
                )
            }
        }

        let request = try GroupUrlRequest.list.asURLRequest()
        let response: MockGroupsResponse = try await networkManager.perform(request)
        return response.items.map { detail in
            MeetupGroup(
                id: detail.id,
                name: detail.name,
                location: detail.location,
                memberCount: detail.members.count,
                summary: detail.summary
            )
        }
    }

    nonisolated func fetchGroupDetail(groupID: Int) async throws -> GroupDetail {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))

            guard let detail = try loadMockGroupDetails().first(where: { $0.id == groupID }) else {
                throw GroupsRepositoryError.groupNotFound
            }

            return detail
        }

        let request = try GroupUrlRequest.detail(groupID: groupID).asURLRequest()
        let response: MockGroupDetailDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
    }

    nonisolated func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GroupsRepositoryError.invalidMemberName
        }

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(150))
            let nextID = (groupDetail.members.map(\.id).max() ?? 0) + 1
            let newMember = GroupMember(id: nextID, name: trimmedName, role: "Member")
            return GroupDetail(
                id: groupDetail.id,
                name: groupDetail.name,
                location: groupDetail.location,
                summary: groupDetail.summary,
                members: groupDetail.members + [newMember]
            )
        }

        let request = try GroupUrlRequest.addMember(groupID: groupDetail.id, name: trimmedName).asURLRequest()
        let response: MockGroupDetailDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
    }

    nonisolated func addUserProfile(_ userProfile: UserProfile, toGroupID groupID: Int) async throws -> GroupDetail {
        let groupDetail = try await fetchGroupDetail(groupID: groupID)

        guard groupDetail.members.contains(where: { $0.name.caseInsensitiveCompare(userProfile.username) == .orderedSame }) == false else {
            throw GroupsRepositoryError.memberAlreadyExists
        }

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(150))
            let nextID = max((groupDetail.members.map(\.id).max() ?? 0) + 1, userProfile.id + 100)
            let newMember = GroupMember(id: nextID, name: userProfile.username, role: "Member")
            return GroupDetail(
                id: groupDetail.id,
                name: groupDetail.name,
                location: groupDetail.location,
                summary: groupDetail.summary,
                members: groupDetail.members + [newMember]
            )
        }

        let request = try GroupUrlRequest.addUserProfile(groupID: groupID, userID: userProfile.id).asURLRequest()
        let response: MockGroupDetailDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
    }

    nonisolated func deleteMember(memberID: Int, from groupDetail: GroupDetail) async throws -> GroupDetail {
        guard groupDetail.members.contains(where: { $0.id == memberID }) else {
            throw GroupsRepositoryError.memberNotFound
        }

        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(150))
            let updatedMembers = groupDetail.members.filter { $0.id != memberID }
            return GroupDetail(
                id: groupDetail.id,
                name: groupDetail.name,
                location: groupDetail.location,
                summary: groupDetail.summary,
                members: updatedMembers
            )
        }

        let request = try GroupUrlRequest.deleteMember(groupID: groupDetail.id, memberID: memberID).asURLRequest()
        let response: MockGroupDetailDTO = try await networkManager.perform(request)
        return response.toGroupDetail()
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

private struct MockGroupsResponse: Decodable, Sendable {
    let items: [MockGroupDetailDTO]
}

private struct MockGroupDetailDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let location: String?
    let summary: String?
    let members: [MockGroupMemberDTO]

    func toGroupDetail() -> GroupDetail {
        GroupDetail(
            id: id,
            name: name,
            location: location,
            summary: summary,
            members: members.map { $0.toGroupMember() }
        )
    }
}

private struct MockGroupMemberDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let role: String

    func toGroupMember() -> GroupMember {
        GroupMember(id: id, name: name, role: role)
    }
}
