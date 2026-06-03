import Foundation

enum NearbyEventVisibility: String, Identifiable, Sendable {
    case `public`
    case `private`
    case external

    var id: String { rawValue }

    var title: String {
        switch self {
        case .public:
            return "Public"
        case .private:
            return "Private"
        case .external:
            return "External"
        }
    }
}

enum NearbyEventCategory: String, CaseIterable, Identifiable, Sendable, CustomStringConvertible {
    case music = "Music"
    case sports = "Sports"
    case artsAndTheatre = "Arts & Theatre"
    case family = "Family"
    case comedy = "Comedy"
    case film = "Film"
    case miscellaneous = "Miscellaneous"

    var id: String { rawValue }

    var title: String { rawValue }

    var description: String { title }
}

enum NearbyEventAgeGroup: String, CaseIterable, Identifiable, Sendable, CustomStringConvertible {
    case family
    case kids
    case teen
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .family:
            return "Family"
        case .kids:
            return "Kids"
        case .teen:
            return "Teen"
        case .all:
            return "All Ages"
        }
    }

    var eventLabel: String {
        switch self {
        case .family:
            return "Family"
        case .kids:
            return "Kids"
        case .teen:
            return "Teen"
        case .all:
            return "All ages"
        }
    }

    var description: String { title }
}

struct NearbyEvent: Identifiable, Equatable, Hashable, Sendable {
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
    var isInterested: Bool
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
        isInterested: Bool = false,
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
        self.isInterested = isInterested
        self.visibility = visibility
    }
}
