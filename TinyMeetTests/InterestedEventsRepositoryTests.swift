import CoreLocation
import Foundation
import Testing
@testable import TinyMeet

struct InterestedEventsRepositoryTests {
    struct MockNetworkManager: NetworkManaging {
        let data: Data

        func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
            try JSONDecoder().decode(T.self, from: data)
        }
    }

    @Test func fetchInterestedEventsDecodesResponse() async throws {
        let payload = """
        {
          "items": [
            {
              "id": "2C5A7E61-9B7D-4E10-9ED6-6BE2CDB9D1B1",
              "kind": "nearby",
              "visibility": "public",
              "title": "Playground Picnic Crew",
              "subtitle": "Central Park Playground · Today · 4:00 PM",
              "symbolName": "calendar"
            },
            {
              "id": "4D0D7EC9-3F8A-4F05-AF3C-9DDE7E61B61B",
              "kind": "privateMap",
              "visibility": "private",
              "title": "Backyard Playdate",
              "subtitle": "Today · 4:30 PM",
              "symbolName": "house.fill"
            }
          ]
        }
        """

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let rows = try await repository.fetchInterestedEvents()
        #expect(rows.count == 2)
        #expect(rows.contains(where: { $0.title == "Playground Picnic Crew" && $0.visibility == .public }))
        #expect(rows.contains(where: { $0.title == "Backyard Playdate" && $0.visibility == .private }))
    }

    @Test func fetchInterestedPrivatePlaydatesDecodesCoordinatesAndPeople() async throws {
        let id = UUID()
        let personID = UUID()
        let payload = """
        {
          "items": [
            {
              "id": "\(id.uuidString)",
              "kind": "privateMap",
              "visibility": "private",
              "title": "Backyard Playdate",
              "subtitle": "Today · 4:30 PM",
              "symbolName": "house.fill",
              "tintName": "mint",
              "latitude": 37.3317,
              "longitude": -122.0325,
              "scheduledAt": "2026-04-26T16:30:00-07:00",
              "interestedPeople": [
                {
                  "id": "\(personID.uuidString)",
                  "name": "Amy Chen",
                  "locationName": "Main Library",
                  "latitude": 37.3328,
                  "longitude": -122.0296
                }
              ]
            }
          ]
        }
        """

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        let playdates = try await repository.fetchInterestedPrivatePlaydates()
        #expect(playdates.count == 1)

        let playdate = try #require(playdates.first)
        #expect(playdate.id == id)
        #expect(playdate.title == "Backyard Playdate")
        #expect(abs(playdate.coordinate.latitude - 37.3317) < 0.0001)
        #expect(abs(playdate.coordinate.longitude - (-122.0325)) < 0.0001)
        #expect(playdate.interestedPeople.count == 1)

        let person = try #require(playdate.interestedPeople.first)
        #expect(person.id == personID)
        #expect(person.name == "Amy Chen")
        #expect(person.locationName == "Main Library")
    }

    @Test func setInterestedAndUninterestedUseMutationRequests() async throws {
        let payload = "{}"
        let eventID = UUID()

        let repository = InterestedEventsRepository(
            networkManager: MockNetworkManager(data: try #require(payload.data(using: .utf8))),
            shouldUseMockData: false
        )

        try await repository.setInterested(true, eventID: eventID)
        try await repository.setInterested(false, eventID: eventID)
    }
}
