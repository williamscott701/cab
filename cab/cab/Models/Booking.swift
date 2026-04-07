import Foundation

// MARK: - Flexible ID-or-Object decoding

/// Handles API fields that can be returned as either a plain String ID or a full populated object.
enum IDOrObject<T: Codable>: Codable {
    case id(String)
    case object(T)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let object = try? container.decode(T.self) {
            self = .object(object)
        } else if let id = try? container.decode(String.self) {
            self = .id(id)
        } else {
            throw DecodingError.typeMismatch(
                IDOrObject.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected String or object")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .id(let id): try container.encode(id)
        case .object(let obj): try container.encode(obj)
        }
    }

    var object: T? {
        if case .object(let obj) = self { return obj }
        return nil
    }
}

// MARK: - BookingStatus

enum BookingStatus: String, CaseIterable {
    case pending   = "pending"
    case confirmed = "confirmed"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Booking

struct Booking: Codable, Identifiable {
    let id: String
    let customerId: IDOrObject<User>
    let routeId: IDOrObject<Route>
    let travelDate: String
    let numberOfPeople: Int
    let preferredSeater: Int
    let prefersCNG: Bool
    let status: String
    let assignedCabId: IDOrObject<Cab>?
    let totalAmount: Double
    let customerNotes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case customerId, routeId, travelDate, numberOfPeople, preferredSeater, prefersCNG
        case status, assignedCabId, totalAmount, customerNotes, createdAt
    }

    var route: Route? { routeId.object }
    var assignedCab: Cab? { assignedCabId?.object }
    var customer: User? { customerId.object }

    var statusEnum: BookingStatus { BookingStatus(rawValue: status) ?? .pending }
}

// MARK: - Request body

struct CreateBookingRequest: Encodable {
    let routeId: String
    let travelDate: String
    let numberOfPeople: Int
    let preferredSeater: Int
    let prefersCNG: Bool
    let customerNotes: String?
}
