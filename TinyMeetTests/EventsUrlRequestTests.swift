import Foundation
import Testing
@testable import TinyMeet

struct EventsUrlRequestTests {
    @Test func listPublicRequestUsesApiV1PublicEventsEndpoint() throws {
        let urlRequest = try EventsUrlRequest.listPublic.asURLRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url?.path == "/api/v1/events/public")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func listPrivateRequestUsesApiV1PrivateEventsEndpoint() throws {
        let urlRequest = try EventsUrlRequest.listPrivate.asURLRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url?.path == "/api/v1/events/private")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func createPrivateRequestUsesPrivateEventsEndpointAndEncodesBody() throws {
        let createRequest = CreateEventRequest(
            visibility: .private,
            title: "Playground Party",
            locationName: "Central Park",
            latitude: 0,
            longitude: 0,
            ageRange: "3 - 5",
            themeEmoji: "🎉",
            summary: "Private playdate fun.",
            symbolName: "figure.2.and.child.holdinghands",
            tintName: "mint",
            audienceType: "friends",
            groupID: nil,
            invitedUIDs: ["friend-1", "friend-2"],
            eventURL: nil,
            scheduledAt: "2026-05-03T13:56:44.745Z"
        )

        let urlRequest = try EventsUrlRequest.create(createRequest).asURLRequest()
        let body = try #require(urlRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let invitedUIDs = try #require(json["invited_uids"] as? [String])

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.url?.path == "/api/v1/events/private")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(json["title"] as? String == "Playground Party")
        #expect(json["location_name"] as? String == "Central Park")
        #expect(json["age_range"] as? String == "3 - 5")
        #expect(json["theme_emoji"] as? String == "🎉")
        #expect(json["summary"] as? String == "Private playdate fun.")
        #expect(json["audience_type"] as? String == "friends")
        #expect(json["scheduled_at"] as? String == "2026-05-03T13:56:44.745Z")
        #expect(invitedUIDs == ["friend-1", "friend-2"])
    }

    @Test func createPublicRequestUsesPublicEventsEndpointAndEncodesBody() throws {
        let createRequest = CreateEventRequest(
            visibility: .public,
            title: "Community Picnic",
            locationName: "Town Green",
            latitude: 0,
            longitude: 0,
            ageRange: "4 - 7",
            themeEmoji: "🌳",
            summary: "Bring snacks and meet local families.",
            symbolName: nil,
            tintName: nil,
            audienceType: nil,
            groupID: nil,
            invitedUIDs: nil,
            eventURL: "https://tinymeet.app/events/community-picnic",
            scheduledAt: "2026-05-03T14:15:45.592Z"
        )

        let urlRequest = try EventsUrlRequest.create(createRequest).asURLRequest()
        let body = try #require(urlRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.url?.path == "/api/v1/events/public")
        #expect(json["title"] as? String == "Community Picnic")
        #expect(json["location_name"] as? String == "Town Green")
        #expect(json["theme_emoji"] as? String == "🌳")
        #expect(json["summary"] as? String == "Bring snacks and meet local families.")
        #expect(json["event_url"] as? String == "https://tinymeet.app/events/community-picnic")
        #expect(json["audience_type"] == nil)
        #expect(json["invited_uids"] == nil)
        #expect(json["scheduled_at"] as? String == "2026-05-03T14:15:45.592Z")
    }
}
