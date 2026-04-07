import SwiftUI

struct AllBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var statusFilter: String = "all"

    private let filters = ["all", "pending", "confirmed", "completed", "cancelled"]

    private var filtered: [Booking] {
        guard statusFilter != "all" else { return bookings }
        return bookings.filter { $0.status == statusFilter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if filtered.isEmpty {
                    ContentUnavailableView("No Bookings", systemImage: "list.clipboard")
                } else {
                    List(filtered) { booking in
                        NavigationLink {
                            AdminBookingDetailView(bookingId: booking.id, onUpdate: {
                                Task { await loadBookings() }
                            })
                        } label: {
                            AdminBookingRow(booking: booking)
                        }
                    }
                }
            }
            .navigationTitle("All Bookings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(filters, id: \.self) { f in
                            Button(f.capitalized) { statusFilter = f }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task { await loadBookings() }
            .refreshable { await loadBookings() }
        }
    }

    private func loadBookings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let path = statusFilter == "all" ? "/api/bookings" : "/api/bookings?status=\(statusFilter)"
            bookings = try await APIClient.shared.perform(path)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Admin Booking Row

struct AdminBookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let user = booking.customer {
                    Text(user.name).font(.headline)
                } else {
                    Text("Booking").font(.headline)
                }
                Spacer()
                StatusBadge(status: booking.statusEnum)
            }
            if let route = booking.route {
                Text("\(route.from) → \(route.to)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label(booking.travelDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("₹\(Int(booking.totalAmount))")
                    .font(.caption.bold())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AllBookingsView()
        .environment(AuthManager())
}
