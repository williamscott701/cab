import Foundation

struct PriceEntry: Codable {
    let seaterCapacity: Int
    let isCNG: Bool
    let price: Double
}

struct Route: Codable, Identifiable {
    let id: String
    let from: String
    let to: String
    let prices: [PriceEntry]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case from, to, prices
    }

    /// Returns the price matching the given seater capacity and CNG preference, or nil.
    func price(forSeater seater: Int, isCNG: Bool) -> Double? {
        prices?.first { $0.seaterCapacity == seater && $0.isCNG == isCNG }?.price
    }
}
