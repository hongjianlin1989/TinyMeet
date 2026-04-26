import Foundation

enum NearbyEventVisibility: String, CaseIterable, Identifiable {
    case `public`
    case `private`

    var id: String { rawValue }

    var title: String {
        switch self {
        case .public:
            return "Public"
        case .private:
            return "Private"
        }
    }
}

struct NearbyEvent: Identifiable, Equatable {
    let id: UUID
    let title: String
    let locationName: String
    let timeDescription: String
    let ageRange: String
    let distanceDescription: String
    let hostName: String
    let attendeeSummary: String
    let themeEmoji: String
    let summary: String
    let eventUrl: String?
    let visibility: NearbyEventVisibility

    init(
        id: UUID = UUID(),
        title: String,
        locationName: String,
        timeDescription: String,
        ageRange: String,
        distanceDescription: String,
        hostName: String,
        attendeeSummary: String,
        themeEmoji: String,
        summary: String,
        eventUrl: String? = nil,
        visibility: NearbyEventVisibility
    ) {
        self.id = id
        self.title = title
        self.locationName = locationName
        self.timeDescription = timeDescription
        self.ageRange = ageRange
        self.distanceDescription = distanceDescription
        self.hostName = hostName
        self.attendeeSummary = attendeeSummary
        self.themeEmoji = themeEmoji
        self.summary = summary
        self.eventUrl = eventUrl
        self.visibility = visibility
    }
}
