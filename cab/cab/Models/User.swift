import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let role: String?
    let createdAt: String?

    var isAdmin: Bool { role == "admin" }
    var isCustomer: Bool { role == "customer" }

    // Auth endpoints return { "id": ... }
    // Mongoose populated documents return { "_id": ... }
    // This custom decoder handles both.
    private enum CodingKeys: String, CodingKey {
        case mongoId = "_id"
        case plainId = "id"
        case name, email, phone, role, createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let mid = try? c.decodeIfPresent(String.self, forKey: .mongoId) {
            id = mid
        } else {
            id = try c.decode(String.self, forKey: .plainId)
        }
        name = try c.decode(String.self, forKey: .name)
        email = try c.decode(String.self, forKey: .email)
        phone = try c.decode(String.self, forKey: .phone)
        role = try c.decodeIfPresent(String.self, forKey: .role)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .mongoId)
        try c.encode(name, forKey: .name)
        try c.encode(email, forKey: .email)
        try c.encode(phone, forKey: .phone)
        try c.encode(role, forKey: .role)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}
