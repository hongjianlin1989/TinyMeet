import CoreLocation
import Foundation

struct InterestedEventListResponse: Decodable, Sendable {
    let events: [InterestedEventRecordDTO]
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
    let id: UUID
    let name: String
    let locationName: String
    let latitude: Double
    let longitude: Double

    func toInterestedPersonLocation() -> InterestedPersonLocation {
        InterestedPersonLocation(
            id: id,
            name: name,
            locationName: locationName,
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
