//
//  UrlRequest.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ProfileUrlRequest {
    case getUserProfile
    
    var path: String {
        switch self {
        case .getUserProfile:
            return "/getUserProfile"
        }
    }
    
    var method: String {
        switch self {
        case .getUserProfile:
            return "GET"
        }
    }
    
    func asURLRequest() -> URLRequest {
        let url: URL

        switch self {
        case .getUserProfile:
            url = APIConfig.baseURL.appending(path: path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
