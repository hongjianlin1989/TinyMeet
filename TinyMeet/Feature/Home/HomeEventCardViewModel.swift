import Foundation
import SwiftUI

struct HomeEventCardViewModel {
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
    var interestButtonTitle: String { "Interested" }
    var interestButtonSystemImage: String { event.isInterested ? "heart.fill" : "heart" }

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
        }
    }

    var visibilityBadgeColor: Color {
        switch event.visibility {
        case .public:
            return TinyMeetTheme.sky.opacity(0.22)
        case .private:
            return TinyMeetTheme.peach.opacity(0.25)
        }
    }

    func interestedTapped() {
        onInterestTapped()
    }
}
//import Combine
//import Foundation
//import SwiftUI
//
//@MainActor
//final class HomeEventCardViewModel: ObservableObject {
//    let event: NearbyEvent
//
//    init(event: NearbyEvent) {
//        self.event = event
//    }
//
//    var title: String { event.title }
//    var locationName: String { event.locationName }
//    var timeDescription: String { event.timeDescription }
//    var ageRange: String { event.ageRange }
//    var distanceDescription: String { event.distanceDescription }
//    var hostName: String { event.hostName }
//    var attendeeSummary: String { event.attendeeSummary }
//    var themeEmoji: String { event.themeEmoji }
//    var summary: String { event.summary }
//    var eventUrlText: String? { event.eventUrl }
//    var visibilityTitle: String { event.visibility.title }
//
//    var eventURL: URL? {
//        guard let eventUrlText,
//              let url = URL(string: eventUrlText),
//              let scheme = url.scheme,
//              scheme.isEmpty == false else {
//            return nil
//        }
//
//        return url
//    }
//
//    var visibilitySymbolName: String {
//        switch event.visibility {
//        case .public:
//            return "globe"
//        case .private:
//            return "lock.fill"
//        }
//    }
//
//    var visibilityBadgeColor: Color {
//        switch event.visibility {
//        case .public:
//            return TinyMeetTheme.sky.opacity(0.22)
//        case .private:
//            return TinyMeetTheme.peach.opacity(0.25)
//        }
//    }
//
//    func interestedTapped() {
//        onInterestTapped()
//    }
//}
