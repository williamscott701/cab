import SwiftUI

struct MyBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                          description: Text(error))
                } else if bookings.isEmpty {
                    ContentUnavailableView("No Bookings Yet", systemImage: "ticket",
                                          description: Text("Book your first ride from the Routes tab."))
                } else {
                    List(bookings) { booking in
                        NavigationLink {
                            BookingDetailView(bookingId: booking.id)
                        } label: {
                            BookingRow(booking: booking)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Bookings")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        if bookings.isEmpty { isLoading = true }
        error = nil
        defer { isLoading = false }
        do { bookings = try await APIClient.shared.perform("/api/bookings/my") }
        catch is CancellationError { }
        catch { self.error = error.localizedDescription }
    }
}

// MARK: - Booking Row

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background(statusColor.opacity(0.12), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                if let route = booking.route {
                    Text("\(route.from) → \(route.to)")
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                } else {
                    Text("Booking")
                        .font(.body.weight(.medium))
                }

                HStack(spacing: 8) {
                    Text(booking.briefDate)
                    Text("₹\(Int(booking.totalAmount))")
                        .foregroundStyle(.tint)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(status: booking.statusEnum)
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: String {
        switch booking.statusEnum {
        case .pending:   return "clock.fill"
        case .confirmed: return "car.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch booking.statusEnum {
        case .pending:   return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return .secondary
        }
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
        case .cancelled: return .secondary
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: .capsule)
            .foregroundStyle(color)
    }
}

#Preview { MyBookingsView().environment(AuthManager()) }
