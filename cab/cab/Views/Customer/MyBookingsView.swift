import SwiftUI

struct MyBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading bookings…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if bookings.isEmpty {
                    ContentUnavailableView(
                        "No Bookings",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Your bookings will appear here.")
                    )
                } else {
                    List(bookings) { booking in
                        NavigationLink {
                            BookingDetailView(bookingId: booking.id)
                        } label: {
                            BookingRow(booking: booking)
                        }
                    }
                }
            }
            .navigationTitle("My Bookings")
            .task { await loadBookings() }
            .refreshable { await loadBookings() }
        }
    }

    private func loadBookings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            bookings = try await APIClient.shared.perform("/api/bookings/my")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Booking Row

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let route = booking.route {
                    Text("\(route.from) → \(route.to)")
                        .font(.headline)
                } else {
                    Text("Booking")
                        .font(.headline)
                }
                Spacer()
                StatusBadge(status: booking.statusEnum)
            }

            HStack {
                Label(booking.travelDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("₹\(Int(booking.totalAmount))")
                    .font(.subheadline.bold())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: BookingStatus

    var color: Color {
        switch status {
        case .pending:   return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    MyBookingsView()
        .environment(AuthManager())
}
