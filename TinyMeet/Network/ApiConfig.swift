//
//  ApiConfig.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

enum ApiConfig {
    static let baseURL = URL(string: "https://api.tinymeet.mock")!
    static let timeoutInterval: TimeInterval = 15
}
