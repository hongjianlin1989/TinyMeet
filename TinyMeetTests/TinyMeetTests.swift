//
//  TinyMeetTests.swift
//  TinyMeetTests
//
//  Created by Hongjian Lin on 3/25/26.
//

import Testing
@testable import TinyMeet

struct TinyMeetTests {

    @Test func groupsRepositoryAddsAndDeletesMember() async throws {
        let repository = GroupsRepository()
        let originalDetail = try await repository.fetchGroupDetail(groupID: 1)

        #expect(originalDetail.members.count > 0)

        let addedDetail = try await repository.addMember(named: "Taylor Brooks", to: originalDetail)
        #expect(addedDetail.members.count == originalDetail.members.count + 1)
        #expect(addedDetail.members.contains(where: { $0.name == "Taylor Brooks" }))

        let addedMember = try #require(addedDetail.members.first(where: { $0.name == "Taylor Brooks" }))
        let deletedDetail = try await repository.deleteMember(memberID: addedMember.id, from: addedDetail)

        #expect(deletedDetail.members.count == originalDetail.members.count)
        #expect(deletedDetail.members.contains(where: { $0.id == addedMember.id }) == false)
    }
}
