import Foundation

enum NearbyEventVisibility: String, CaseIterable, Identifiable, Sendable {
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
    case music
    case sports
    case arts
    case film
    case food
    case family

    var id: String { rawValue }

    var description: String {
        rawValue.capitalized
    }
}

enum NearbyEventAgeGroup: String, CaseIterable, Identifiable, Sendable, CustomStringConvertible {
    case kids
    case adults
    case all

    var id: String { rawValue }

    var description: String {
        switch self {
        case .kids:
            return "Kids"
        case .adults:
            return "Adults"
        case .all:
            return "All Ages"
        }
    }

    var eventLabel: String {
        switch self {
        case .kids:
            return "Kids"
        case .adults:
            return "Adults"
        case .all:
            return "All ages"
        }
    }
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
