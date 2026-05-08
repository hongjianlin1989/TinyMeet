import Foundation
import Testing
@testable import TinyMeet

struct CreateEventViewModelAddressSearchTests {
    @MainActor
    @Test func updateLocationQueryLoadsAddressSuggestions() async throws {
        let recorder = SearchQueryRecorder()
        let suggestion = AddressSuggestion(title: "1600 Amphitheatre Pkwy", subtitle: "Mountain View, CA")

        let viewModel = CreateEventViewModel(
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: []),
            addressSearchService: MockAddressSearchService(
                suggestionsHandler: { query in
                    await recorder.record(query)
                    return [suggestion]
                }
            ),
            locationSearchDebounceNanoseconds: 0
        )

        viewModel.updateLocationQuery("1600 Amph")
        try await Task.sleep(nanoseconds: 50_000_000)

        let queries = await recorder.queries
        #expect(queries == ["1600 Amph"])
        #expect(viewModel.locationSuggestions == [suggestion])
    }

    @MainActor
    @Test func selectingSuggestedLocationStoresCoordinatesAndEditingClearsThem() async throws {
        let suggestion = AddressSuggestion(title: "1600 Amphitheatre Pkwy", subtitle: "Mountain View, CA")

        let viewModel = CreateEventViewModel(
            friendsRepository: MockCreateEventFriendsRepository(friends: []),
            groupsRepository: MockCreateEventGroupsRepository(groups: []),
            addressSearchService: MockAddressSearchService(
                suggestionsHandler: { _ in [suggestion] },
                resolveHandler: { selectedSuggestion in
                    #expect(selectedSuggestion == suggestion)
                    return ResolvedAddressLocation(
                        suggestion: selectedSuggestion,
                        latitude: 37.422,
                        longitude: -122.084058
                    )
                }
            ),
            locationSearchDebounceNanoseconds: 0
        )

        viewModel.updateLocationQuery("1600 Amph")
        try await Task.sleep(nanoseconds: 50_000_000)
        await viewModel.selectLocationSuggestion(suggestion)

        #expect(viewModel.location == "1600 Amphitheatre Pkwy, Mountain View, CA")
        #expect(viewModel.latitudeText == "37.422")
        #expect(viewModel.longitudeText == "-122.084058")
        #expect(viewModel.locationCoordinateSummary == "Coordinates: 37.422, -122.084058")

        viewModel.updateLocationQuery("1600 Amphitheatre Parkway")
        #expect(viewModel.latitudeText.isEmpty)
        #expect(viewModel.longitudeText.isEmpty)
        #expect(viewModel.locationCoordinateSummary == nil)
    }
}
