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
        token: String? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
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
        let token: String? = authenticated ? await MainActor.run { KeychainManager.getToken() } : nil
        let req = try makeRequest(path: path, method: method, body: body, token: token)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw mapURLError(error)
        }
        try validate(response: response, data: data, authenticated: authenticated)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let nested = json["data"] {
                let nestedData = try JSONSerialization.data(withJSONObject: nested)
                if let value = try? decoder.decode(T.self, from: nestedData) {
                    return value
                }
            }
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
        let token: String? = authenticated ? await MainActor.run { KeychainManager.getToken() } : nil
        let req = try makeRequest(path: path, method: method, body: body, token: token)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw mapURLError(error)
        }
        try validate(response: response, data: data, authenticated: authenticated)
    }

    // MARK: - Validation helper

    private func validate(response: URLResponse, data: Data, authenticated: Bool) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown("Bad server response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let message: String? }
            let serverMessage = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.message

            if http.statusCode == 401 {
                if authenticated {
                    Task { @MainActor in
                        NotificationCenter.default.post(name: .apiSessionExpired, object: nil)
                    }
                    throw APIError.unauthorized
                }
                throw APIError.serverError(401, serverMessage ?? "Invalid credentials")
            }

            let message = serverMessage ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
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
