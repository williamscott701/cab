import SwiftUI

struct MyBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if bookings.isEmpty {
                    ContentUnavailableView(
                        "No Bookings Yet",
                        systemImage: "ticket",
                        description: Text("Book your first ride from the Routes tab.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(bookings) { booking in
                                NavigationLink {
                                    BookingDetailView(bookingId: booking.id)
                                } label: {
                                    BookingRow(booking: booking)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
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

// MARK: - Booking Row Card

struct BookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 0) {
            // Status strip
            HStack {
                StatusBadge(status: booking.statusEnum)
                Spacer()
                Text("₹\(Int(booking.totalAmount))")
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            // Route
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Circle().fill(.tint).frame(width: 7, height: 7)
                    Rectangle().fill(Color.accentColor.opacity(0.3)).frame(width: 1.5).frame(maxHeight: .infinity)
                    Circle().fill(Color(.systemGray3)).frame(width: 7, height: 7)
                }
                .padding(.vertical, 3)

                if let route = booking.route {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(route.from)
                            .font(.subheadline.weight(.semibold))
                        Text(route.to)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Route details loading…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Meta row
            HStack(spacing: 16) {
                Label(booking.travelDate, systemImage: "calendar")
                Label("\(booking.preferredSeater)-Seater", systemImage: "person.2.fill")
                if booking.prefersCNG {
                    Label("CNG", systemImage: "leaf.fill")
                        .foregroundStyle(.green)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
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

    var icon: String {
        switch status {
        case .pending:   return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var body: some View {
        Label(status.displayName, systemImage: icon)
            .font(.caption.bold())
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.13))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    MyBookingsView()
        .environment(AuthManager())
}
