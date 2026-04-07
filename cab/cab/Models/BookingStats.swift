import Foundation

struct BookingStats: Decodable {
    let currentMonth: CurrentMonth
    let monthly: [MonthEntry]
    let allTime: AllTime

    struct CurrentMonth: Decodable {
        let revenue: Double
        let completed: Int
        let confirmed: Int
        let pending: Int
        let cancelled: Int

        var totalBookings: Int { completed + confirmed + pending + cancelled }
    }

    struct MonthEntry: Decodable, Identifiable {
        let month: String
        let revenue: Double
        let count: Int

        var id: String { month }

        var displayMonth: String {
            let parts = month.split(separator: "-")
            guard parts.count == 2,
                  let m = Int(parts[1]) else { return month }
            let symbols = DateFormatter().shortMonthSymbols ?? []
            let name = (1...12).contains(m) ? symbols[m - 1] : month
            return "\(name) \(parts[0])"
        }
    }

    struct AllTime: Decodable {
        let revenue: Double
        let count: Int
    }
}
