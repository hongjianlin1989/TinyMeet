import Foundation

protocol EventsRepositoryProtocol: Sendable {
    func fetchPublicEvents() async throws -> [NearbyEvent]
    func fetchPrivateEvents() async throws -> [NearbyEvent]
    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent
}

struct EventsRepository: EventsRepositoryProtocol {
    private let networkManager: NetworkManaging
    private let bundle: Bundle
    private let decoder: JSONDecoder

    nonisolated init(
        networkManager: NetworkManaging? = nil,
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.networkManager = networkManager ?? NetworkManager()
        self.bundle = bundle
        self.decoder = decoder
    }

    func fetchPublicEvents() async throws -> [NearbyEvent] {

        let request = try EventsUrlRequest.listPublic.asURLRequest()
        let response: PublicEventsResponse = try await networkManager.perform(request)
        return response.events.map { $0.toNearbyEvent() }
    }

    func fetchPrivateEvents() async throws -> [NearbyEvent] {
        let request = try EventsUrlRequest.listPrivate.asURLRequest()
        let response: PrivateEventsResponse = try await networkManager.perform(request)
        return response.events.map { $0.toNearbyEvent() }
    }

    func createEvent(_ request: CreateEventRequest) async throws -> NearbyEvent {
        let urlRequest = try EventsUrlRequest.create(request).asURLRequest()
        let _: CreateEventResponse = try await networkManager.perform(urlRequest)
        return request.toNearbyEvent()
    }

    private func loadMockResponse<T: Decodable>(named resourceName: String) throws -> T {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw EventsRepositoryError.missingMockResource(resourceName)
        }

        let data = try Data(contentsOf: url)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw EventsRepositoryError.failedToDecodeMock(resourceName, underlying: error)
        }
    }
}

enum EventsRepositoryError: LocalizedError {
    case missingMockResource(String)
    case failedToDecodeMock(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingMockResource(let name):
            return "Missing mock events JSON resource: \(name).json"
        case .failedToDecodeMock(let name, let underlying):
            return "Failed to decode mock events JSON resource \(name).json (\(underlying.localizedDescription))"
        }
    }
}

struct EventsListResponse: Decodable, Sendable {
    let items: [EventDTO]
}

struct PublicEventsResponse: Decodable, Sendable {
    let events: [PublicEventDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case events
        case nextCursor = "next_cursor"
    }
}

struct PrivateEventsResponse: Decodable, Sendable {
    let events: [PrivateEventDTO]
    let nextCursor: String?

    private enum CodingKeys: String, CodingKey {
        case events
        case nextCursor = "next_cursor"
    }
}

struct EventDTO: Decodable, Sendable {
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

    func toNearbyEvent(visibility: NearbyEventVisibility) -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName,
            timeDescription: timeDescription,
            ageRange: ageRange,
            distanceDescription: distanceDescription,
            hostName: hostName,
            attendeeSummary: attendeeSummary,
            themeEmoji: themeEmoji,
            summary: summary,
            eventUrl: eventUrl,
            visibility: visibility
        )
    }
}

struct PublicEventDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let locationName: String?
    let ageRange: String?
    let themeEmoji: String?
    let summary: String?
    let eventUrl: String?
    let hostName: String?
    let attendeeCount: Int
    let scheduledAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case locationName = "location_name"
        case ageRange = "age_range"
        case themeEmoji = "theme_emoji"
        case summary
        case eventUrl = "event_url"
        case hostName = "host_name"
        case attendeeCount = "attendee_count"
        case scheduledAt = "scheduled_at"
    }

    func toNearbyEvent() -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName ?? "Location TBD",
            timeDescription: EventDisplayFormatter.timeDescription(from: scheduledAt),
            ageRange: ageRange ?? "All ages",
            distanceDescription: "Community",
            hostName: EventDisplayFormatter.hostLabel(for: hostName, fallback: "Hosted by TinyMeet"),
            attendeeSummary: EventDisplayFormatter.attendeeSummary(count: attendeeCount),
            themeEmoji: themeEmoji ?? "🎉",
            summary: summary ?? "Join other families for a fun local meetup.",
            eventUrl: eventUrl,
            visibility: .public
        )
    }
}

struct PrivateEventDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let ageRange: String?
    let themeEmoji: String?
    let symbolName: String?
    let tintName: String?
    let summary: String?
    let hostUID: String?
    let hostName: String?
    let audienceType: String
    let groupID: UUID?
    let attendeeCount: Int
    let isInterested: Bool
    let scheduledAt: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case locationName = "location_name"
        case latitude
        case longitude
        case ageRange = "age_range"
        case themeEmoji = "theme_emoji"
        case symbolName = "symbol_name"
        case tintName = "tint_name"
        case summary
        case hostUID = "host_uid"
        case hostName = "host_name"
        case audienceType = "audience_type"
        case groupID = "group_id"
        case attendeeCount = "attendee_count"
        case isInterested = "is_interested"
        case scheduledAt = "scheduled_at"
        case createdAt = "created_at"
    }

    func toNearbyEvent() -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName ?? "Private location",
            timeDescription: EventDisplayFormatter.timeDescription(from: scheduledAt),
            ageRange: ageRange ?? "All ages",
            distanceDescription: EventDisplayFormatter.privateAudienceLabel(from: audienceType),
            hostName: EventDisplayFormatter.hostLabel(for: hostName, fallback: "Hosted privately"),
            attendeeSummary: EventDisplayFormatter.attendeeSummary(count: attendeeCount),
            themeEmoji: themeEmoji ?? "🏡",
            summary: summary ?? "A private meetup shared with your TinyMeet circle.",
            eventUrl: nil,
            isInterested: isInterested,
            visibility: .private
        )
    }
}

private enum EventDisplayFormatter {
    private static let inputFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let inputFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d · h:mm a"
        return formatter
    }()

    static func timeDescription(from scheduledAt: String) -> String {
        let parsedDate = inputFormatterWithFractionalSeconds.date(from: scheduledAt)
            ?? inputFormatter.date(from: scheduledAt)

        guard let parsedDate else {
            return scheduledAt
        }

        return outputFormatter.string(from: parsedDate)
    }

    static func hostLabel(for hostName: String?, fallback: String) -> String {
        guard let hostName, hostName.isEmpty == false else {
            return fallback
        }

        return "Hosted by \(hostName)"
    }

    static func attendeeSummary(count: Int) -> String {
        if count == 1 {
            return "1 person attending"
        }

        return "\(count) people attending"
    }

    static func privateAudienceLabel(from audienceType: String) -> String {
        switch audienceType.lowercased() {
        case "group":
            return "Group"
        case "friends":
            return "Friends"
        default:
            return "Private"
        }
    }
}

struct CreateEventRequest: Encodable, Sendable {
    let visibility: NearbyEventVisibility
    let title: String
    let locationName: String
    let latitude: Double
    let longitude: Double
    let ageRange: String
    let themeEmoji: String
    let summary: String
    let symbolName: String?
    let tintName: String?
    let audienceType: String?
    let groupID: String?
    let invitedUIDs: [String]?
    let eventURL: String?
    let scheduledAt: String

    private enum CodingKeys: String, CodingKey {
        case title
        case locationName = "location_name"
        case latitude
        case longitude
        case ageRange = "age_range"
        case themeEmoji = "theme_emoji"
        case symbolName = "symbol_name"
        case tintName = "tint_name"
        case summary
        case audienceType = "audience_type"
        case groupID = "group_id"
        case invitedUIDs = "invited_uids"
        case eventURL = "event_url"
        case scheduledAt = "scheduled_at"
    }

    var nearbyEventVisibility: NearbyEventVisibility {
        visibility
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(locationName, forKey: .locationName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(ageRange, forKey: .ageRange)
        try container.encode(themeEmoji, forKey: .themeEmoji)
        try container.encode(summary, forKey: .summary)
        try container.encode(scheduledAt, forKey: .scheduledAt)

        switch visibility {
        case .public:
            try container.encodeIfPresent(eventURL, forKey: .eventURL)
        case .private:
            try container.encodeIfPresent(symbolName, forKey: .symbolName)
            try container.encodeIfPresent(tintName, forKey: .tintName)
            try container.encodeIfPresent(audienceType, forKey: .audienceType)
            try container.encodeIfPresent(groupID, forKey: .groupID)
            try container.encodeIfPresent(invitedUIDs, forKey: .invitedUIDs)
        }
    }

    func toNearbyEvent(id: UUID = UUID()) -> NearbyEvent {
        NearbyEvent(
            id: id,
            title: title,
            locationName: locationName,
            timeDescription: EventDisplayFormatter.timeDescription(from: scheduledAt),
            ageRange: ageRange,
            distanceDescription: visibility == .public ? "Community" : "Just created",
            hostName: "Hosted by You",
            attendeeSummary: attendeeSummary,
            themeEmoji: themeEmoji,
            summary: summary,
            eventUrl: visibility == .public ? eventURL : nil,
            visibility: nearbyEventVisibility
        )
    }

    private var attendeeSummary: String {
        guard visibility == .private else {
            return "New public event"
        }

        return audienceType == "group" ? "Private group event" : "Private friends event"
    }
}

private struct CreateEventResponse: Decodable, Sendable {}
