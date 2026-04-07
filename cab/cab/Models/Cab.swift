import Foundation

struct Cab: Codable, Identifiable {
    let id: String
    let driverName: String
    let driverPhone: String
    let vehicleModel: String
    let licensePlate: String
    let color: String
    let seaterCapacity: Int
    let isCNG: Bool
    let isActive: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case driverName, driverPhone, vehicleModel, licensePlate, color
        case seaterCapacity, isCNG, isActive, createdAt
    }
}

struct CreateCabRequest: Encodable {
    let driverName: String
    let driverPhone: String
    let vehicleModel: String
    let licensePlate: String
    let color: String
    let seaterCapacity: Int
    let isCNG: Bool
}
