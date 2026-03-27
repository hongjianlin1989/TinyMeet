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

    @Test func profileRepositoryMockSearchReturnsExpectedUsers() async throws {
        let repository = ProfileRespository()

        let swiftUIResults = try await repository.searchUserProfiles(query: "swiftui")
        #expect(swiftUIResults.contains(where: { $0.username == "miapark" }))
        #expect(swiftUIResults.contains(where: { $0.username == "noahpatel" }))

        let coffeeResults = try await repository.searchUserProfiles(query: " coffee ")
        #expect(coffeeResults.contains(where: { $0.username == "amychen" }))
        #expect(coffeeResults.contains(where: { $0.username == "sofiawang" }))

        let emptyResults = try await repository.searchUserProfiles(query: "   ")
        #expect(emptyResults.isEmpty)
    }

    @MainActor
    @Test func discoverViewModelSearchesProfilesAndAddsToGroup() async throws {
        let viewModel = DiscoverViewModel(
            profileRespository: ProfileRespository(),
            groupsRepository: GroupsRepository()
        )

        await viewModel.loadGroups()
        #expect(viewModel.groups.isEmpty == false)

        viewModel.searchText = "bay area"
        await viewModel.searchProfiles()

        #expect(viewModel.profiles.contains(where: { $0.username == "ethannguyen" }))
        #expect(viewModel.profiles.contains(where: { $0.username == "chloegarcia" }))

        let selectedProfile = try #require(viewModel.profiles.first(where: { $0.username == "chloegarcia" }))
        let selectedGroup = try #require(viewModel.groups.first)

        await viewModel.addProfileToGroup(selectedProfile, groupID: selectedGroup.id)
        #expect(viewModel.successMessage?.contains("@chloegarcia") == true)
        #expect(viewModel.errorMessage == nil)
    }
}
