//
//  NetworkManager.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/26/26.
//

import FirebaseAuth
import Foundation

protocol NetworkManaging: Sendable {
    func perform<T: Decodable>(_ request: URLRequest) async throws -> T
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case unsuccessfulStatusCode(Int)
    case decodingFailed
    case missingAuthorizationToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unsuccessfulStatusCode(let code):
            return "The server request failed with status code \(code)."
        case .decodingFailed:
            return "The app could not decode the server response."
        case .missingAuthorizationToken:
            return "The app could not get an authentication token for this request."
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
        let authorizedRequest = try await requestWithAuthorizationIfAvailable(from: request)
        let (data, response) = try await session.data(for: authorizedRequest)

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

    private func requestWithAuthorizationIfAvailable(from request: URLRequest) async throws -> URLRequest {
        guard request.value(forHTTPHeaderField: "Authorization") == nil,
              let currentUser = Auth.auth().currentUser else {
            return request
        }

        let idToken = try await currentUser.tinyMeetIDToken()
        var authorizedRequest = request
        authorizedRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        return authorizedRequest
    }
}

private extension User {
    func tinyMeetIDToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            getIDTokenForcingRefresh(false) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token, token.isEmpty == false else {
                    continuation.resume(throwing: NetworkError.missingAuthorizationToken)
                    return
                }

                continuation.resume(returning: token)
            }
        }
    }
}
