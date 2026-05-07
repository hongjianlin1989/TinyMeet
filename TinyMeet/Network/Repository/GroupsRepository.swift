import Foundation

protocol GroupsRepositoryProtocol: Sendable {
    func fetchGroups() async throws -> [MeetupGroup]
    func fetchGroupInvites() async throws -> [GroupInvite]
    func acceptGroupInvite(_ invite: GroupInvite) async throws
    func rejectGroupInvite(_ invite: GroupInvite) async throws
    func createGroup(_ request: CreateGroupRequest) async throws
    func fetchGroupDetail(groupID: String) async throws -> GroupDetail
    func deleteGroup(groupID: String) async throws
    func leaveGroup(groupID: String) async throws -> Bool
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

    func fetchGroupInvites() async throws -> [GroupInvite] {
        let request = try GroupUrlRequest.invites.asURLRequest()
        let response: [GroupInviteResponseDTO] = try await networkManager.perform(request)
        return response.map { $0.toGroupInvite() }
    }

    func acceptGroupInvite(_ invite: GroupInvite) async throws {
        try await respondToGroupInvite(invite, action: .accept)
    }

    func rejectGroupInvite(_ invite: GroupInvite) async throws {
        try await respondToGroupInvite(invite, action: .reject)
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

    func leaveGroup(groupID: String) async throws -> Bool {
        let request = try GroupUrlRequest.leaveGroup(groupID: groupID).asURLRequest()
        let response: GeneralResponse = try await networkManager.perform(request)
        return response.success ?? true
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

    private func respondToGroupInvite(_ invite: GroupInvite, action: FriendRequestResponseAction) async throws {
        let request = try GroupUrlRequest.respondToInvite(inviteID: invite.id, action: action).asURLRequest()
        let _: GeneralResponse = try await networkManager.perform(request)
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
