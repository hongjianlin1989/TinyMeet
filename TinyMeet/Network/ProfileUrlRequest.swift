//
//  UrlRequest.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ProfileUrlRequest {
    case getUserProfile

    private var path: String {
        switch self {
        case .getUserProfile:
            return "/users/profile"
        }
    }

    private var method: String {
        switch self {
        case .getUserProfile:
            return "GET"
        }
    }

    func asURLRequest() -> URLRequest {
        let url = ApiConfig.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = ApiConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
