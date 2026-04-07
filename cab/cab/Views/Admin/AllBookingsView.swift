import SwiftUI

private enum BookingSort: String, CaseIterable {
    case newest     = "Newest First"
    case oldest     = "Oldest First"
    case highAmount = "Amount: High → Low"
    case lowAmount  = "Amount: Low → High"
}

struct AllBookingsView: View {

    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var statusFilter = "all"
    @State private var sortOrder: BookingSort = .newest
    @State private var searchText = ""

    private let statusFilters = ["all", "pending", "confirmed", "completed", "cancelled"]

    private var filtered: [Booking] {
        var list = statusFilter == "all" ? bookings : bookings.filter { $0.status == statusFilter }
        if !searchText.isEmpty {
            list = list.filter {
                $0.customer?.name.localizedCaseInsensitiveContains(searchText) == true ||
                $0.route?.from.localizedCaseInsensitiveContains(searchText) == true ||
                $0.route?.to.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        switch sortOrder {
        case .newest:     list.sort { $0.createdAt > $1.createdAt }
        case .oldest:     list.sort { $0.createdAt < $1.createdAt }
        case .highAmount: list.sort { $0.totalAmount > $1.totalAmount }
        case .lowAmount:  list.sort { $0.totalAmount < $1.totalAmount }
        }
        return list
    }

    private var isFiltered: Bool { statusFilter != "all" || sortOrder != .newest }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "wifi.slash")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView("No Bookings", systemImage: "list.clipboard",
                                          description: Text("Nothing here yet."))
                } else {
                    List {
                        ForEach(filtered) { booking in
                                NavigationLink {
                                    AdminBookingDetailView(bookingId: booking.id) {
                                        Task { await load() }
                                    }
                                } label: {
                                    AdminBookingRow(booking: booking)
                                }
                            }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name or route")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Filter by Status") {
                            Picker("Status", selection: $statusFilter) {
                                ForEach(statusFilters, id: \.self) { f in
                                    Text(f.capitalized).tag(f)
                                }
                            }
                        }
                        Section("Sort by") {
                            Picker("Sort", selection: $sortOrder) {
                                ForEach(BookingSort.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isFiltered
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
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
        HStack(spacing: 10) {
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background(statusColor.opacity(0.12), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(booking.customer?.name ?? "Booking")
                    .font(.subheadline.weight(.medium))

                if let route = booking.route {
                    Text("\(route.from) → \(route.to)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(booking.briefDate)
                    Text("₹\(Int(booking.totalAmount))")
                        .foregroundStyle(.tint)
                }
                .font(.caption)
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

#Preview { AllBookingsView().environment(AuthManager()) }
