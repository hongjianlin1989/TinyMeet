//
//  UrlRequest.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ProfileUrlRequest {
    case getUserProfile
    case addFriend(userID: Int)

    private var path: String {
        switch self {
        case .getUserProfile:
            return "/users/profile"
        case .addFriend(let userID):
            return "/users/\(userID)/friends"
        }
    }

    private var method: String {
        switch self {
        case .getUserProfile:
            return "GET"
        case .addFriend:
            return "POST"
        }
    }

    func asURLRequest() -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if case .addFriend = self {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
