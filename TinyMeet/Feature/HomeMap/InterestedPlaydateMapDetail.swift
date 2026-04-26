import CoreLocation
import Foundation

struct InterestedPersonLocation: Identifiable, Equatable {
    let id: UUID
    let name: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D

    init(
        id: UUID = UUID(),
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
    let interestedPeople: [InterestedPersonLocation]

    var id: UUID { event.id }
    var title: String { event.title }
    var subtitle: String { event.subtitle }
    var coordinate: CLLocationCoordinate2D { event.coordinate }
    var tintName: String { event.tintName }
    var symbolName: String { event.symbolName }

    static func == (lhs: InterestedPlaydateMapDetail, rhs: InterestedPlaydateMapDetail) -> Bool {
        lhs.event == rhs.event
            && lhs.scheduledAt == rhs.scheduledAt
            && lhs.interestedPeople == rhs.interestedPeople
    }
}
