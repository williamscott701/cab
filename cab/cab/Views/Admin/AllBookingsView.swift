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
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { f in
                            FilterChip(label: f.capitalized, isSelected: statusFilter == f) {
                                statusFilter = f
                                Task { await loadBookings() }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider()

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
                    } else if filtered.isEmpty {
                        ContentUnavailableView(
                            "No Bookings",
                            systemImage: "list.clipboard",
                            description: Text("No bookings match the current filter.")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { booking in
                                    NavigationLink {
                                        AdminBookingDetailView(bookingId: booking.id, onUpdate: {
                                            Task { await loadBookings() }
                                        })
                                    } label: {
                                        AdminBookingRow(booking: booking)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("All Bookings")
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

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Admin Booking Row

struct AdminBookingRow: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let user = booking.customer {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Text(user.name.prefix(1).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(.tint)
                        }
                        Text(user.name)
                            .font(.headline)
                    }
                } else {
                    Text("Booking").font(.headline)
                }
                Spacer()
                StatusBadge(status: booking.statusEnum)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 14)

            // Route + meta
            VStack(alignment: .leading, spacing: 6) {
                if let route = booking.route {
                    Label("\(route.from) → \(route.to)", systemImage: "map")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                HStack(spacing: 14) {
                    Label(booking.travelDate, systemImage: "calendar")
                    Label("₹\(Int(booking.totalAmount))", systemImage: "indianrupeesign")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    AllBookingsView()
        .environment(AuthManager())
}
