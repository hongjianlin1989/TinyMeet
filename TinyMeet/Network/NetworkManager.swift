//
//  NetworkManager.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import Foundation

protocol NetworkManaging: Sendable {
    func perform<T: Decodable>(_ request: URLRequest) async throws -> T
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case unsuccessfulStatusCode(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unsuccessfulStatusCode(let code):
            return "The server request failed with status code \(code)."
        case .decodingFailed:
            return "The app could not decode the server response."
        }
    }
}

struct NetworkManager: NetworkManaging {
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.unsuccessfulStatusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Failed to decode: \(error)")
            throw NetworkError.decodingFailed
        }
    }
}
