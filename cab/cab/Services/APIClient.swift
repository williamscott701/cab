import Foundation

// MARK: - Session expired notification

extension Notification.Name {
    static let apiSessionExpired = Notification.Name("apiSessionExpired")
}

// MARK: - Errors

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case noData
    case unauthorized
    case serverError(Int, String)
    case decodingFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Something went wrong. Please try again."
        case .noData:                   return "No data received from server."
        case .unauthorized:             return "Session expired. Please log in again."
        case .serverError(_, let msg):  return msg
        case .decodingFailed:           return "Something went wrong. Please try again."
        case .unknown(let msg):         return msg
        }
    }
}

// MARK: - Login response

struct LoginResponse: Decodable, Sendable {
    let token: String
    let user: User
}

// MARK: - Wrapped response envelope { data: T }

private struct WrappedResponse<T: Decodable>: Decodable {
    let data: T
}

// MARK: - APIClient

actor APIClient {

    static let shared = APIClient()

    private let baseURL = "https://sea-lion-app-f62aj.ondigitalocean.app"

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()

    private let encoder: JSONEncoder = JSONEncoder()
    private let decoder: JSONDecoder = JSONDecoder()

    private init() {}

    // MARK: - Request builder

    private func makeRequest(
        path: String,
        method: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = KeychainManager.getToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    // MARK: - Perform with response body

    func perform<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let req = try makeRequest(path: path, method: method, body: body, authenticated: authenticated)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw mapURLError(error)
        }
        try validate(response: response, data: data)

        if let direct = try? decoder.decode(T.self, from: data) {
            return direct
        }
        if let wrapped = try? decoder.decode(WrappedResponse<T>.self, from: data) {
            return wrapped.data
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    /// For endpoints that return no body (204) or where success is enough.
    func performVoid(
        _ path: String,
        method: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws {
        let req = try makeRequest(path: path, method: method, body: body, authenticated: authenticated)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw mapURLError(error)
        }
        try validate(response: response, data: data)
    }

    // MARK: - Validation helper

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown("Bad server response.")
        }
        if http.statusCode == 401 {
            Task { @MainActor in
                NotificationCenter.default.post(name: .apiSessionExpired, object: nil)
            }
            throw APIError.unauthorized
        }
        guard (200..<300).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let message: String? }
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.message
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw APIError.serverError(http.statusCode, message)
        }
    }

    // MARK: - URL error mapping

    private func mapURLError(_ error: Error) -> APIError {
        guard let urlError = error as? URLError else {
            return .unknown("Something went wrong. Please try again.")
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .unknown("No internet connection. Please check your network.")
        case .timedOut:
            return .unknown("Request timed out. Please try again.")
        case .cancelled:
            return .unknown("Request was cancelled.")
        default:
            return .unknown("Something went wrong. Please try again.")
        }
    }
}
