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
    let driverName: String?
    let driverPhone: String?
    let licensePlate: String?
    let totalAmount: Double
    let customerNotes: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case customerId, routeId, travelDate, numberOfPeople, preferredSeater, prefersCNG
        case status, driverName, driverPhone, licensePlate, totalAmount, customerNotes, createdAt
    }

    var route: Route? { routeId.object }
    var customer: User? { customerId.object }

    var statusEnum: BookingStatus { BookingStatus(rawValue: status) ?? .pending }

    /// Parses the travelDate string into a Date, handling multiple formats.
    private var parsedDate: Date? {
        // ISO 8601 with fractional seconds: "2026-04-07T00:00:00.000Z"
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFrac.date(from: travelDate) { return date }
        // ISO 8601 without fractional seconds
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: travelDate) { return date }
        // Plain date: "2026-04-07"
        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        if let date = ymd.date(from: travelDate) { return date }
        return nil
    }

    /// Full date for detail views: "Apr 7, 2026 · 12:00 AM"
    var formattedDate: String {
        guard let date = parsedDate else { return travelDate }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy · h:mm a"
        return f.string(from: date)
    }

    /// Short date for list rows: "7 Apr, 12:00 AM"
    var briefDate: String {
        guard let date = parsedDate else { return travelDate }
        let f = DateFormatter()
        f.dateFormat = "d MMM, h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Request bodies

struct CreateBookingRequest: Encodable {
    let routeId: String
    let travelDate: String
    let numberOfPeople: Int
    let preferredSeater: Int
    let prefersCNG: Bool
    let customerNotes: String?
}

struct UpdateBookingRequest: Encodable {
    let travelDate: String
    let numberOfPeople: Int
    let preferredSeater: Int
    let prefersCNG: Bool
    let customerNotes: String?
}
