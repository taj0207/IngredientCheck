//
//  NetworkClient.swift
//  IngredientCheck
//
//  Created on 2025-11-02
//

import Foundation

/// Generic network client for making HTTP requests
class NetworkClient {

    // MARK: - Properties

    private let session: URLSession
    private let defaultTimeout: TimeInterval

    // MARK: - Initialization

    init(session: URLSession = .shared, timeout: TimeInterval = 30) {
        self.session = session
        self.defaultTimeout = timeout
    }

    // MARK: - Public Methods

    /// Perform a generic HTTP request
    /// - Parameters:
    ///   - request: URLRequest to perform
    ///   - retries: Number of retry attempts
    /// - Returns: Response data and HTTP response
    /// - Throws: NetworkError if request fails
    func perform(
        _ request: URLRequest,
        retries: Int = APIConfig.maxRetryAttempts
    ) async throws -> (Data, HTTPURLResponse) {
        let startTime = Date()

        Logger.logNetworkRequest(
            url: request.url?.absoluteString ?? "unknown",
            method: request.httpMethod ?? "GET"
        )

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            let duration = Date().timeIntervalSince(startTime)
            Logger.logNetworkResponse(
                url: request.url?.absoluteString ?? "unknown",
                statusCode: httpResponse.statusCode,
                duration: duration
            )

            // Handle HTTP errors
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(
                    statusCode: httpResponse.statusCode,
                    data: data
                )
            }

            return (data, httpResponse)

        } catch let error as NetworkError {
            throw error
        } catch {
            // Retry on network errors
            if retries > 0 {
                Logger.warning("Request failed, retrying... (\(retries) attempts left)", category: .network)
                try await Task.sleep(nanoseconds: UInt64(APIConfig.retryDelay * 1_000_000_000))
                return try await perform(request, retries: retries - 1)
            }

            throw NetworkError.connectionError(error)
        }
    }

    /// Perform request and decode JSON response
    /// - Parameters:
    ///   - request: URLRequest to perform
    ///   - type: Type to decode into
    ///   - retries: Number of retry attempts
    /// - Returns: Decoded object
    /// - Throws: NetworkError if request or decoding fails
    func perform<T: Decodable>(
        _ request: URLRequest,
        decoding type: T.Type,
        retries: Int = APIConfig.maxRetryAttempts
    ) async throws -> T {
        let (data, _) = try await perform(request, retries: retries)

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            Logger.error("Failed to decode response", error: error, category: .network)
            throw NetworkError.decodingError(error)
        }
    }

    /// Create URLRequest with common headers
    /// - Parameters:
    ///   - url: Target URL
    ///   - method: HTTP method
    ///   - headers: Additional headers
    ///   - body: Request body data
    /// - Returns: Configured URLRequest
    func createRequest(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = defaultTimeout

        // Set common headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("IngredientCheck/\(Constants.appVersion)", forHTTPHeaderField: "User-Agent")

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = body {
            request.httpBody = body
        }

        return request
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case connectionError(Error)
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("network.error.invalid_url", comment: "Invalid URL")
        case .invalidResponse:
            return NSLocalizedString("network.error.invalid_response", comment: "Invalid response from server")
        case .connectionError(let error):
            return String(format: NSLocalizedString("network.error.connection", comment: "Connection error: %@"), error.localizedDescription)
        case .httpError(let statusCode, let data):
            if let data = data, let message = String(data: data, encoding: .utf8) {
                return "HTTP \(statusCode): \(message)"
            }
            return "HTTP Error: \(statusCode)"
        case .decodingError(let error):
            return String(format: NSLocalizedString("network.error.decoding", comment: "Failed to decode response: %@"), error.localizedDescription)
        case .encodingError(let error):
            return String(format: NSLocalizedString("network.error.encoding", comment: "Failed to encode request: %@"), error.localizedDescription)
        case .timeout:
            return NSLocalizedString("network.error.timeout", comment: "Request timed out")
        case .cancelled:
            return NSLocalizedString("network.error.cancelled", comment: "Request was cancelled")
        }
    }
}
