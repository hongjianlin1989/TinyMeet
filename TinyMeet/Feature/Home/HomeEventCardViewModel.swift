import Combine
import Foundation
import SwiftUI

@MainActor
final class HomeEventCardViewModel: ObservableObject {
    let event: NearbyEvent

    init(event: NearbyEvent) {
        self.event = event
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
    var visibilityTitle: String { event.visibility.title }

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
        // Hook for future event interest action.
    }
}
