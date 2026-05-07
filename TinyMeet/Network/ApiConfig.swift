//
//  ApiConfig.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ApiConfig {
    private static let productionBaseURLString = "https://tinymeet-api.licongchen.org"
    private static let apiPathPrefix = "/api/v1"

    static let baseURL: URL = {
        let configuredBaseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let normalizedBaseURL = configuredBaseURL?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let normalizedBaseURL,
           !normalizedBaseURL.isEmpty,
           let url = URL(string: normalizedBaseURL),
           url.scheme != nil,
           url.host != nil {
            return url
        }

        return URL(string: productionBaseURLString) ?? URL(fileURLWithPath: "/")
    }()

    static let timeoutInterval: TimeInterval = 15

    static func apiURL(path: String) -> URL {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedPath: String
        if trimmedPath.isEmpty {
            normalizedPath = apiPathPrefix
        } else if trimmedPath == apiPathPrefix || trimmedPath.hasPrefix("\(apiPathPrefix)/") {
            normalizedPath = trimmedPath
        } else if trimmedPath.hasPrefix("/") {
            normalizedPath = apiPathPrefix + trimmedPath
        } else {
            normalizedPath = apiPathPrefix + "/" + trimmedPath
        }

        return baseURL.appending(path: normalizedPath)
    }
}
