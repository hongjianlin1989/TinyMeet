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
