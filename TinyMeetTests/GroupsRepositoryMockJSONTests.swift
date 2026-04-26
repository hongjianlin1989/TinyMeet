import Foundation
import Testing
@testable import TinyMeet

struct GroupsRepositoryMockJSONTests {
    @Test func mockJSONDecodesGroupsAndDedicatedDetailsWithMembers() async throws {
        let repository = GroupsRepository(shouldUseMockData: true, bundle: .main)

        let groups = try await repository.fetchGroups()
        #expect(groups.isEmpty == false)
        #expect(groups.allSatisfy { $0.memberCount > 0 })

        let firstGroup = try #require(groups.first)
        let detail = try await repository.fetchGroupDetail(groupID: firstGroup.id)
        #expect(detail.id == firstGroup.id)
        #expect(detail.members.isEmpty == false)
        #expect(detail.memberCount == detail.members.count)
        #expect(detail.members.allSatisfy { $0.name.isEmpty == false && $0.role.isEmpty == false })
    }
}
