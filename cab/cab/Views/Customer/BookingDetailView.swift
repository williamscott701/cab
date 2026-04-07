import SwiftUI

struct BookingDetailView: View {

    let bookingId: String

    @State private var booking: Booking?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
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
            } else if let booking {
                ScrollView {
                    VStack(spacing: 16) {
                        // Status
                        HStack {
                            Spacer()
                            StatusBadge(status: booking.statusEnum)
                            Spacer()
                        }

                        // Route info
                        if let route = booking.route {
                            InfoCard(title: "Route") {
                                LabeledValue(label: "From", value: route.from)
                                LabeledValue(label: "To", value: route.to)
                                LabeledValue(label: "Type", value: route.displayRouteType)
                            }
                        }

                        // Trip details
                        InfoCard(title: "Trip Details") {
                            LabeledValue(label: "Travel Date", value: booking.travelDate)
                            LabeledValue(label: "Passengers", value: "\(booking.numberOfPeople)")
                            LabeledValue(label: "Seater", value: "\(booking.preferredSeater)-Seater")
                            LabeledValue(label: "CNG", value: booking.prefersCNG ? "Yes" : "No")
                            LabeledValue(label: "Total", value: "₹\(Int(booking.totalAmount))")
                        }

                        if let notes = booking.customerNotes, !notes.isEmpty {
                            InfoCard(title: "Notes") {
                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Cab info — only shown when confirmed
                        if booking.statusEnum == .confirmed, let cab = booking.assignedCab {
                            InfoCard(title: "Your Cab") {
                                LabeledValue(label: "Driver", value: cab.driverName)
                                LabeledValue(label: "Phone", value: cab.driverPhone)
                                LabeledValue(label: "Vehicle", value: cab.vehicleModel)
                                LabeledValue(label: "Plate", value: cab.licensePlate)
                                LabeledValue(label: "Color", value: cab.color)
                            }
                        }
                    }
                    .padding()
                }
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

// MARK: - Helpers

struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        BookingDetailView(bookingId: "preview")
    }
    .environment(AuthManager())
}
