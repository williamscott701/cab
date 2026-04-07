import Foundation
import Observation

@Observable
@MainActor
final class AuthManager {

    var isLoggedIn: Bool = false
    var role: String?
    var currentUser: User?

    init() {
        guard let token = KeychainManager.getToken(),
              let payload = AuthManager.decodeJWTPayload(token)
        else { return }

        // Reject expired tokens
        if let exp = payload["exp"] as? Double, exp <= Date().timeIntervalSince1970 {
            KeychainManager.deleteToken()
            return
        }

        isLoggedIn = true
        role = payload["role"] as? String
    }

    // MARK: - Session actions

    func login(token: String, user: User) {
        KeychainManager.saveToken(token)
        isLoggedIn = true
        role = user.role
        currentUser = user
    }

    func logout() async {
        try? await APIClient.shared.performVoid("/api/auth/logout", method: "POST")
        clearSession()
    }

    func deleteAccount() async throws {
        try await APIClient.shared.performVoid("/api/auth/account", method: "DELETE")
        clearSession()
    }

    func loadCurrentUser() async throws {
        let user: User = try await APIClient.shared.perform("/api/auth/me")
        currentUser = user
        role = user.role
    }

    // MARK: - Private

    private func clearSession() {
        KeychainManager.deleteToken()
        isLoggedIn = false
        role = nil
        currentUser = nil
    }

    // MARK: - JWT payload decoder (no third-party library)

    /// Decodes the payload segment of a JWT and returns it as [String: Any].
    static func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }

        // Convert base64url → base64
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to multiple of 4
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        return json
    }
}
