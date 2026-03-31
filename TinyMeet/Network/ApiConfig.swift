//
//  ApiConfig.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ApiConfig {
    private static let productionBaseURLString = "https://api.tinymeet.mock"

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
}
