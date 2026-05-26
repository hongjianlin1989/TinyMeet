import Foundation
import Testing
@testable import TinyMeet

struct EventDetailViewModelTests {
    @Test func publicEventExposesLinkAndVisibilityMetadata() {
        let eventID = UUID(uuidString: "69F150E0-FE18-43D4-AF40-7A1337B9B6FC")!
        let event = NearbyEvent(
            id: eventID,
            title: "Playground Picnic Crew",
            locationName: "Central Park Playground",
            timeDescription: "Today · 4:00 PM",
            ageRange: "Ages 3-5",
            distanceDescription: "0.4 mi away",
            hostName: "Hosted by Mia",
            attendeeSummary: "8 families going",
            themeEmoji: "🛝",
            summary: "Meet other families for snacks.",
            eventUrl: "https://tinymeet.app/events/playground-picnic-crew",
            visibility: .public
        )

        let viewModel = EventDetailViewModel(event: event)

        #expect(viewModel.visibilityTitle == "Public")
        #expect(viewModel.visibilitySymbolName == "globe")
        #expect(viewModel.eventURL == URL(string: "https://tinymeet.app/events/playground-picnic-crew"))
        #expect(viewModel.eventDeepLinkURL == URL(string: "tinymeet://events/69f150e0-fe18-43d4-af40-7a1337b9b6fc"))
        #expect(viewModel.sharePayload.url == viewModel.eventDeepLinkURL)
        #expect(viewModel.sharePayload.message.contains("Playground Picnic Crew"))
        #expect(viewModel.interestButtonTitle == "Mark Interested")
        #expect(viewModel.interestButtonSystemImage == "heart")
    }

    @Test func privateEventUsesLockBadgeAndInvokesInterestAction() {
        var tapCount = 0
        let event = NearbyEvent(
            title: "Neighborhood Sandbox Circle",
            locationName: "Oak Lane Backyard",
            timeDescription: "Saturday · 2:00 PM",
            ageRange: "Ages 2-5",
            distanceDescription: "0.6 mi away",
            hostName: "Hosted by Emma",
            attendeeSummary: "Private group · 4 families",
            themeEmoji: "🪣",
            summary: "A cozy backyard sandbox playdate.",
            eventUrl: "not a url",
            isInterested: true,
            visibility: .private
        )

        let viewModel = EventDetailViewModel(
            event: event,
            onInterestTapped: {
                tapCount += 1
            }
        )

        viewModel.interestedTapped()

        #expect(tapCount == 1)
        #expect(viewModel.visibilityTitle == "Private")
        #expect(viewModel.visibilitySymbolName == "lock.fill")
        #expect(viewModel.eventURL == nil)
        #expect(viewModel.interestButtonTitle == "Interested")
        #expect(viewModel.interestButtonSystemImage == "heart.fill")
    }
}
