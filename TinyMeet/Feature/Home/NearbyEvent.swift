import Foundation

struct NearbyEvent: Identifiable, Equatable {
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
        summary: String
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
    }
}
