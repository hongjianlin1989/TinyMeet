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
}

enum ProfileUrlRequest {
    case getUserProfile
    case friendRequests
    case respondToFriendRequest(requestID: String, action: FriendRequestResponseAction)
    case searchProfiles(query: String)
    case addFriend(userID: String)
    case removeFriend(userID: String)

    private var path: String {
        switch self {
        case .getUserProfile:
            return "/api/v1/users/profile"
        case .friendRequests:
            return "/api/v1/friends/requests"
        case .respondToFriendRequest(let requestID, _):
            return "/api/v1/friends/requests/\(requestID)/respond"
        case .searchProfiles:
            return "/api/v1/users/search"
        case .addFriend(let userID), .removeFriend(let userID):
            return "/users/\(userID)/friends"
        }
    }

    private var method: String {
        switch self {
        case .getUserProfile, .friendRequests, .searchProfiles:
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

        if case .addFriend = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else if case .respondToFriendRequest(_, _) = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = responseBody
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

    private var responseBody: Data? {
        guard case .respondToFriendRequest(_, let action) = self else {
            return nil
        }

        return Data(#"{"response":"\#(action.rawValue)"}"#.utf8)
    }
}
