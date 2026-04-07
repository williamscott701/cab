import SwiftUI

struct BookingDetailView: View {

    let bookingId: String

    @State private var booking: Booking?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
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
            } else if let booking {
                ScrollView {
                    VStack(spacing: 16) {
                        // Status hero
                        StatusHero(status: booking.statusEnum, amount: booking.totalAmount)

                        // Route
                        if let route = booking.route {
                            InfoCard(title: "Route", icon: "map.fill") {
                                RouteTimeline(from: route.from, to: route.to)
                                Divider()
                                LabeledValue(label: "Type", value: route.displayRouteType)
                            }
                        }

                        // Trip details
                        InfoCard(title: "Trip Details", icon: "suitcase.fill") {
                            LabeledValue(label: "Travel Date", value: booking.travelDate)
                            Divider()
                            LabeledValue(label: "Passengers", value: "\(booking.numberOfPeople)")
                            Divider()
                            LabeledValue(label: "Cab Size", value: "\(booking.preferredSeater)-Seater")
                            Divider()
                            LabeledValue(label: "CNG", value: booking.prefersCNG ? "Yes" : "No")
                        }

                        if let notes = booking.customerNotes, !notes.isEmpty {
                            InfoCard(title: "Your Notes", icon: "text.bubble.fill") {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Cab info — only shown when confirmed
                        if booking.statusEnum == .confirmed || booking.statusEnum == .completed,
                           let cab = booking.assignedCab {
                            InfoCard(title: "Your Cab", icon: "car.fill") {
                                LabeledValue(label: "Driver", value: cab.driverName)
                                Divider()
                                LabeledValue(label: "Phone", value: cab.driverPhone)
                                Divider()
                                LabeledValue(label: "Vehicle", value: cab.vehicleModel)
                                Divider()
                                LabeledValue(label: "Plate", value: cab.licensePlate)
                                Divider()
                                LabeledValue(label: "Color", value: cab.color)
                            }
                        } else if booking.statusEnum == .pending {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.questionmark")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Awaiting Assignment")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Cab details will appear here once confirmed.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.bottom, 24)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Booking Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBooking() }
    }

    private func loadBooking() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            booking = try await APIClient.shared.perform("/api/bookings/my/\(bookingId)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Status Hero

struct StatusHero: View {
    let status: BookingStatus
    let amount: Double

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
        case .confirmed: return "checkmark.seal.fill"
        case .completed: return "flag.checkered.2.crossed"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(color)
            Text(status.displayName)
                .font(.title2.bold())
            Text("₹\(Int(amount))")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Route Timeline (reusable)

struct RouteTimeline: View {
    let from: String
    let to: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle().fill(.tint).frame(width: 8, height: 8)
                Rectangle().fill(Color.accentColor.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity)
                Circle().fill(Color(.systemGray3)).frame(width: 8, height: 8)
            }
            .padding(.vertical, 3)
            VStack(alignment: .leading, spacing: 14) {
                Text(from).font(.subheadline.weight(.semibold))
                Text(to).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Info Card

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 10) {
                content
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Labeled Value

struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    NavigationStack {
        BookingDetailView(bookingId: "preview")
    }
    .environment(AuthManager())
}
