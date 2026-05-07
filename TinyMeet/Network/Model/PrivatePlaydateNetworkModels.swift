import CoreLocation
import Foundation

struct PrivatePlaydateListResponse: Decodable, Sendable {
    let items: [PrivatePlaydateDTO]
}

struct PrivatePlaydateDTO: Decodable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let tintName: String
    let symbolName: String

    func toMapItem() -> PrivateEventMapItem {
        PrivateEventMapItem(
            id: id,
            title: title,
            subtitle: subtitle,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            tintName: tintName,
            symbolName: symbolName
        )
    }
}
