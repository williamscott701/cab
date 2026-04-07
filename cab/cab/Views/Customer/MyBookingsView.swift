import SwiftUI

struct MyBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = false
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
                    ContentUnavailableView("No Bookings", systemImage: "ticket",
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
        isLoading = true; error = nil
        defer { isLoading = false }
        do { bookings = try await APIClient.shared.perform("/api/bookings/my") }
        catch { self.error = error.localizedDescription }
    }
}

// MARK: - Booking Row

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            // Status color stripe
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let route = booking.route {
                        Text("\(route.from) → \(route.to)").font(.headline)
                    } else {
                        Text("Booking").font(.headline)
                    }
                    Spacer()
                    StatusBadge(status: booking.statusEnum)
                }
                HStack(spacing: 12) {
                    Label(booking.formattedDate, systemImage: "calendar")
                    Text("₹\(Int(booking.totalAmount))")
                        .foregroundStyle(.tint)
                        .fontWeight(.medium)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch booking.statusEnum {
        case .pending:   return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return Color(.systemGray4)
        }
    }
}

// MARK: - Status Badge (shared across all views)

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

    var icon: String {
        switch status {
        case .pending:   return "clock"
        case .confirmed: return "checkmark.circle.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var body: some View {
        Label(status.displayName, systemImage: icon)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview { MyBookingsView().environment(AuthManager()) }
