import CoreLocation
import Foundation

struct InterestedEventListResponse: Decodable, Sendable {
    let events: [InterestedEventRecordDTO]
}

struct PrivateEventAttendeesResponse: Decodable, Sendable {
    let attendees: [PrivateEventAttendeeDTO]
}

struct InterestedEventRecordDTO: Decodable, Sendable {
    enum EventType: String, Decodable, Sendable {
        case `public`
        case `private`
    }

    let id: UUID
    let eventID: UUID
    let eventType: EventType
    let uid: String
    let title: String?
    let subtitle: String?
    let locationName: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: String
    let scheduledAt: String?
    let endsAt: String?
    let symbolName: String?
    let tintName: String?
    let interestedPeople: [InterestedPersonLocationDTO]?

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case eventType = "event_type"
        case uid
        case title
        case subtitle
        case locationName = "location_name"
        case latitude
        case longitude
        case createdAt = "created_at"
        case scheduledAt = "scheduled_at"
        case endsAt = "ends_at"
        case symbolName = "symbol_name"
        case tintName = "tint_name"
        case interestedPeople = "interested_people"
    }

    static func parseISO8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

struct InterestedPersonLocationDTO: Decodable, Sendable {
    let id: String
    let name: String
    let locationName: String
    let latitude: Double
    let longitude: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case locationName
        case latitude
        case longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let id = try? container.decode(String.self, forKey: .id) {
            self.id = id
        } else {
            let uuid = try container.decode(UUID.self, forKey: .id)
            self.id = uuid.uuidString
        }

        self.name = try container.decode(String.self, forKey: .name)
        self.locationName = try container.decode(String.self, forKey: .locationName)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
    }

    func toInterestedPersonLocation() -> InterestedPersonLocation {
        InterestedPersonLocation(
            id: id,
            name: name,
            locationName: locationName,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}

struct PrivateEventAttendeeDTO: Decodable, Sendable {
    let uid: String
    let displayName: String
    let avatarURL: URL?
    let latitude: Double
    let longitude: Double
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case uid
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case latitude
        case longitude
        case updatedAt = "updated_at"
    }

    func toInterestedPersonLocation() -> InterestedPersonLocation {
        InterestedPersonLocation(
            id: uid,
            name: displayName,
            locationName: "",
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}

struct InterestedEventMutationResponse: Decodable, Sendable {
    let id: UUID
    let eventID: UUID
    let eventType: String

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case eventType = "event_type"
    }
}
