import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let role: String
    let createdAt: String?

    var isAdmin: Bool { role == "admin" }
    var isCustomer: Bool { role == "customer" }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, phone, role, createdAt
    }
}
