import CoreLocation
import Foundation

struct InterestedPersonLocation: Identifiable, Equatable {
    let id: String
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D

    init(
        id: String = UUID().uuidString,
        name: String,
        locationName: String,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.coordinate = coordinate
    }

    static func == (lhs: InterestedPersonLocation, rhs: InterestedPersonLocation) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.locationName == rhs.locationName
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

struct InterestedPlaydateMapDetail: Identifiable, Equatable {
    let event: PrivateEventMapItem
    let scheduledAt: Date?
    let endsAt: Date?
    let interestedPeople: [InterestedPersonLocation]

    var id: UUID { event.id }
    var title: String { event.title }
    var subtitle: String { event.subtitle }
    var coordinate: CLLocationCoordinate2D { event.coordinate }
    var tintName: String { event.tintName }
    var symbolName: String { event.symbolName }
    var startTimeText: String? { Self.startTimeFormatter.stringIfPossible(from: scheduledAt) }
    var pickerTitle: String {
        guard let startTimeText else { return title }
        return "\(title), start: \(startTimeText)"
    }

    static func == (lhs: InterestedPlaydateMapDetail, rhs: InterestedPlaydateMapDetail) -> Bool {
        lhs.event == rhs.event
            && lhs.scheduledAt == rhs.scheduledAt
            && lhs.endsAt == rhs.endsAt
            && lhs.interestedPeople == rhs.interestedPeople
    }

    private static let startTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

private extension DateFormatter {
    func stringIfPossible(from date: Date?) -> String? {
        guard let date else { return nil }
        return string(from: date).lowercased()
    }
}
