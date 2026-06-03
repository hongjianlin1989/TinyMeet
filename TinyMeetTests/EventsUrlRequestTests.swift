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
            latitude: 37.3349,
            longitude: -122.0090,
            ageRange: "3 - 5",
            themeEmoji: "🛝",
            summary: "Private playdate fun.",
            symbolName: "figure.play",
            tintName: "orange",
            audienceType: "friends",
            groupID: nil,
            invitedUIDs: ["friend-2", "friend-1"],
            eventURL: nil,
            scheduledAt: "2026-05-03T13:56:44.745Z",
            endsAt: "2026-05-03T15:56:44.745Z"
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
        #expect(json["latitude"] as? Double == 37.3349)
        #expect(json["longitude"] as? Double == -122.0090)
        #expect(json["age_range"] as? String == "3 - 5")
        #expect(json["theme_emoji"] as? String == "🛝")
        #expect(json["symbol_name"] as? String == "figure.play")
        #expect(json["tint_name"] as? String == "orange")
        #expect(json["summary"] as? String == "Private playdate fun.")
        #expect(json["audience_type"] as? String == "friends")
        #expect(json["scheduled_at"] as? String == "2026-05-03T13:56:44.745Z")
        #expect(json["ends_at"] as? String == "2026-05-03T15:56:44.745Z")
        #expect(invitedUIDs == ["friend-2", "friend-1"])
    }

    @Test func createPublicRequestUsesPublicEventsEndpointAndEncodesBody() throws {
        let createRequest = CreateEventRequest(
            visibility: .public,
            title: "Community Picnic",
            locationName: "Town Green",
            latitude: 37.7749,
            longitude: -122.4194,
            ageRange: "4 - 7",
            themeEmoji: "🌳",
            summary: "Bring snacks and meet local families.",
            symbolName: nil,
            tintName: nil,
            audienceType: nil,
            groupID: nil,
            invitedUIDs: nil,
            eventURL: "https://tinymeet.app/events/community-picnic",
            scheduledAt: "2026-05-03T14:15:45.592Z",
            endsAt: "2026-05-03T16:15:45.592Z"
        )

        let urlRequest = try EventsUrlRequest.create(createRequest).asURLRequest()
        let body = try #require(urlRequest.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.url?.path == "/api/v1/events/public")
        #expect(json["title"] as? String == "Community Picnic")
        #expect(json["location_name"] as? String == "Town Green")
        #expect(json["latitude"] as? Double == 37.7749)
        #expect(json["longitude"] as? Double == -122.4194)
        #expect(json["age_range"] as? String == "4 - 7")
        #expect(json["theme_emoji"] as? String == "🌳")
        #expect(json["summary"] as? String == "Bring snacks and meet local families.")
        #expect(json["event_url"] as? String == "https://tinymeet.app/events/community-picnic")
        #expect(json["audience_type"] == nil)
        #expect(json["invited_uids"] == nil)
        #expect(json["ends_at"] as? String == "2026-05-03T16:15:45.592Z")
        #expect(json["scheduled_at"] as? String == "2026-05-03T14:15:45.592Z")
    }

    @Test func unifiedFeedRequestEncodesRepeatedFilterQueryItems() throws {
        let urlRequest = try EventsUrlRequest.feed(
            types: ["public", "external"],
            categories: ["Music", "Sports"],
            ageGroups: ["kids", "family"],
            postalCode: "10001",
            cursor: "next-page"
        ).asURLRequest()

        let components = try #require(URLComponents(url: try #require(urlRequest.url), resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url?.path == "/api/v1/events/feed")
        #expect(queryItems.filter { $0.name == "types" }.compactMap(\.value) == ["public", "external"])
        #expect(queryItems.filter { $0.name == "categories" }.compactMap(\.value) == ["Music", "Sports"])
        #expect(queryItems.filter { $0.name == "age_groups" }.compactMap(\.value) == ["kids", "family"])
        #expect(queryItems.first(where: { $0.name == "postal_code" })?.value == "10001")
        #expect(queryItems.first(where: { $0.name == "cursor" })?.value == "next-page")
    }
}
