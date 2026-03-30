import CoreLocation
import Foundation

struct PrivateEventMapItem: Identifiable, Equatable {
    static func == (lhs: PrivateEventMapItem, rhs: PrivateEventMapItem) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.tintName == rhs.tintName
            && lhs.symbolName == rhs.symbolName
    }

    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let tintName: String
    let symbolName: String

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        coordinate: CLLocationCoordinate2D,
        tintName: String,
        symbolName: String
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.tintName = tintName
        self.symbolName = symbolName
    }
}

extension PrivateEventMapItem {
    static let mockItems: [PrivateEventMapItem] = [
        PrivateEventMapItem(
            title: "Backyard Playdate",
            subtitle: "Today · 4:30 PM",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            tintName: "pink",
            symbolName: "house.fill"
        ),
        PrivateEventMapItem(
            title: "Private Story Time",
            subtitle: "Tomorrow · 10:00 AM",
            coordinate: CLLocationCoordinate2D(latitude: 37.7768, longitude: -122.4142),
            tintName: "mint",
            symbolName: "book.fill"
        ),
        PrivateEventMapItem(
            title: "Family Picnic Circle",
            subtitle: "Saturday · 11:15 AM",
            coordinate: CLLocationCoordinate2D(latitude: 37.7711, longitude: -122.4236),
            tintName: "orange",
            symbolName: "basket.fill"
        )
    ]
}
