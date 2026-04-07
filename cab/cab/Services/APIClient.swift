import Foundation

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case serverError(Int, String)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:               return "Invalid URL."
        case .noData:                   return "No data received."
        case .unauthorized:             return "Session expired. Please log in again."
        case .serverError(_, let msg):  return msg
        case .decodingError(let e):     return "Failed to parse response: \(e.localizedDescription)"
        case .unknown(let e):           return e.localizedDescription
        }
    }
}

// MARK: - Login response

struct LoginResponse: Decodable {
    let token: String
    let role: String
    let user: User
}

// MARK: - Wrapped response envelope  { data: T }

private struct WrappedResponse<T: Decodable>: Decodable {
    let data: T
}

// MARK: - APIClient

actor APIClient {

    static let shared = APIClient()

    private let baseURL = "http://localhost:3000"

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()

    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        return dec
    }()

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
        let (data, response) = try await session.data(for: req)
        try validate(response: response, data: data)

        // Try direct decode, then wrapped in { data: ... }
        if let direct = try? decoder.decode(T.self, from: data) {
            return direct
        }
        if let wrapped = try? decoder.decode(WrappedResponse<T>.self, from: data) {
            return wrapped.data
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
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
        let (data, response) = try await session.data(for: req)
        try validate(response: response, data: data)
    }

    // MARK: - Validation helper

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["message"]
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw APIError.serverError(http.statusCode, message)
        }
    }
}
