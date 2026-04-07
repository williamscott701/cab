import SwiftUI

struct AllBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var statusFilter = "all"

    private let filters = ["all", "pending", "confirmed", "completed", "cancelled"]

    private var filtered: [Booking] {
        statusFilter == "all" ? bookings : bookings.filter { $0.status == statusFilter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                          description: Text(errorMessage))
                } else if filtered.isEmpty {
                    ContentUnavailableView("No Bookings", systemImage: "list.clipboard",
                                          description: Text("Nothing here yet."))
                } else {
                    List(filtered) { booking in
                        NavigationLink {
                            AdminBookingDetailView(bookingId: booking.id) {
                                Task { await load() }
                            }
                        } label: {
                            AdminBookingRow(booking: booking)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $statusFilter) {
                            ForEach(filters, id: \.self) { f in
                                Text(f.capitalized).tag(f)
                            }
                        }
                    } label: {
                        Image(systemName: statusFilter == "all"
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            bookings = try await APIClient.shared.perform("/api/bookings")
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Admin Booking Row

struct AdminBookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(booking.customer?.name ?? "Booking").font(.headline)
                    Spacer()
                    StatusBadge(status: booking.statusEnum)
                }
                if let route = booking.route {
                    Text("\(route.from) → \(route.to)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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

#Preview { AllBookingsView().environment(AuthManager()) }
