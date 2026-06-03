import Foundation
import SwiftUI

struct EventSharePayload: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let url: URL

    var activityItems: [Any] {
        [message, url]
    }
}

struct EventDetailViewModel {
    let event: NearbyEvent
    let isInterestUpdating: Bool
    let onInterestTapped: () -> Void

    init(
        event: NearbyEvent,
        isInterestUpdating: Bool = false,
        onInterestTapped: @escaping () -> Void = {}
    ) {
        self.event = event
        self.isInterestUpdating = isInterestUpdating
        self.onInterestTapped = onInterestTapped
    }

    var title: String { event.title }
    var locationName: String { event.locationName }
    var timeDescription: String { event.timeDescription }
    var ageRange: String { event.ageRange }
    var distanceDescription: String { event.distanceDescription }
    var hostName: String { event.hostName }
    var attendeeSummary: String { event.attendeeSummary }
    var themeEmoji: String { event.themeEmoji }
    var summary: String { event.summary }
    var eventUrlText: String? { event.eventUrl }
    var visibilityTitle: String { event.visibility.title }
    var isInterested: Bool { event.isInterested }
    var interestButtonTitle: String { isInterested ? "Interested" : "Mark Interested" }
    var interestButtonSystemImage: String { event.isInterested ? "heart.fill" : "heart" }
    var eventDeepLinkURL: URL { DeepLinkHandler.eventDetailURL(for: event.id) }

    var sharePayload: EventSharePayload {
        EventSharePayload(
            title: title,
            message: shareMessage,
            url: eventDeepLinkURL
        )
    }

    var eventURL: URL? {
        guard let eventUrlText,
              let url = URL(string: eventUrlText),
              let scheme = url.scheme,
              scheme.isEmpty == false else {
            return nil
        }

        return url
    }

    var visibilitySymbolName: String {
        switch event.visibility {
        case .public:
            return "globe"
        case .private:
            return "lock.fill"
        case .external:
            return "ticket.fill"
        }
    }

    var visibilityBadgeColor: Color {
        switch event.visibility {
        case .public:
            return TinyMeetTheme.sky.opacity(0.22)
        case .private:
            return TinyMeetTheme.peach.opacity(0.25)
        case .external:
            return TinyMeetTheme.mint.opacity(0.24)
        }
    }

    func interestedTapped() {
        onInterestTapped()
    }

    private var shareMessage: String {
        "Check out \(title) on TinyMeet. Open the event here: \(eventDeepLinkURL.absoluteString)"
    }
}
