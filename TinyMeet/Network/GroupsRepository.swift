import Foundation

protocol GroupsRepositoryProtocol: Sendable {
    nonisolated func fetchGroups() async throws -> [MeetupGroup]
    nonisolated func fetchGroupDetail(groupID: Int) async throws -> GroupDetail
    nonisolated func addMember(named name: String, to groupDetail: GroupDetail) async throws -> GroupDetail
    nonisolated func addUserProfile(_ userProfile: UserProfile, toGroupID groupID: Int) async throws -> GroupDetail
    nonisolated func deleteMember(memberID: Int, from groupDetail: GroupDetail) async throws -> GroupDetail
}

struct GroupsRepository: GroupsRepositoryProtocol, Sendable {
    private let shouldUseMockData: Bool

    nonisolated init(shouldUseMockData: Bool = true) {
        self.shouldUseMockData = shouldUseMockData
    }

    nonisolated func fetchGroups() async throws -> [MeetupGroup] {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(300))
            return MeetupGroup.mockGroups
        }

        return []
    }

    nonisolated func fetchGroupDetail(groupID: Int) async throws -> GroupDetail {
        if shouldUseMockData {
            try await Task.sleep(for: .milliseconds(250))

            guard let detail = GroupDetail.mockDetails.first(where: { $0.id == groupID }) else {
                throw GroupsRepositoryError.groupNotFound
            }

            return detail
        }

        throw GroupsRepositoryError.groupNotFound
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

        throw GroupsRepositoryError.groupNotFound
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

        throw GroupsRepositoryError.groupNotFound
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

        throw GroupsRepositoryError.memberNotFound
    }
}

enum GroupsRepositoryError: LocalizedError {
    case groupNotFound
    case memberNotFound
    case invalidMemberName
    case memberAlreadyExists

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
        }
    }
}
