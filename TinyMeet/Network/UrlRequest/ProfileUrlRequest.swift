//
//  UrlRequest.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum FriendRequestResponseAction: String, Sendable {
    case accept
    case reject

    var acceptValue: Bool {
        switch self {
        case .accept:
            return true
        case .reject:
            return false
        }
    }
}

enum ProfileUrlRequest {
    case getUserProfile
    case friends
    case friendRequests
    case respondToFriendRequest(requestID: String, action: FriendRequestResponseAction)
    case searchProfiles(query: String)
    case addFriend(userID: String)
    case removeFriend(userID: String)

    private var path: String {
        switch self {
        case .getUserProfile:
            return "/api/v1/users/profile"
        case .friends:
            return "/api/v1/friends"
        case .friendRequests:
            return "/api/v1/friends/requests"
        case .respondToFriendRequest(let requestID, _):
            return "/api/v1/friends/requests/\(requestID)/respond"
        case .searchProfiles:
            return "/api/v1/users/search"
        case .addFriend:
            return "/api/v1/friends/requests"
        case .removeFriend(let userID):
            return "/api/v1/friends/\(userID)"
        }
    }

    private var method: String {
        switch self {
        case .getUserProfile, .friends, .friendRequests, .searchProfiles:
            return "GET"
        case .addFriend, .respondToFriendRequest:
            return "POST"
        case .removeFriend:
            return "DELETE"
        }
    }

    func asURLRequest() -> URLRequest {
        let url = resolvedURL()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let requestBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestBody
        }

        return request
    }

    private func resolvedURL() -> URL {
        let url = ApiConfig.baseURL.appending(path: path)

        guard case .searchProfiles(let query) = self,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]

        return components.url ?? url
    }

    private var requestBody: Data? {
        switch self {
        case .respondToFriendRequest(_, let action):
            return Data(#"{"accept":\#(action.acceptValue)}"#.utf8)
        case .addFriend(let userID):
            return Data(#"{"receiver_uid":"\#(userID)"}"#.utf8)
        default:
            return nil
        }
    }
}
