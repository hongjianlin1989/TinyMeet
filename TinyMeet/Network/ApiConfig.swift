//
//  ApiConfig.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ApiConfig {
    static let baseURL: URL = URL(string: "https://api.tinymeet.mock") ?? URL(fileURLWithPath: "/")
    static let timeoutInterval: TimeInterval = 15
}
