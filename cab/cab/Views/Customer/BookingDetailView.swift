import SwiftUI

struct BookingDetailView: View {

    let bookingId: String

    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isCancelling = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                      description: Text(error))
            } else if let booking {
                Form {
                    // Status + amount
                    Section {
                        HStack {
                            StatusBadge(status: booking.statusEnum)
                            Spacer()
                            Text("₹\(Int(booking.totalAmount))").font(.headline)
                        }
                    }

                    // Route
                    if let route = booking.route {
                        Section("Route") {
                            LabeledContent("From", value: route.from)
                            LabeledContent("To", value: route.to)
                        }
                    }

                    // Trip details
                    Section("Trip Details") {
                        LabeledContent("Date", value: booking.formattedDate)
                        LabeledContent("Passengers", value: "\(booking.numberOfPeople)")
                        LabeledContent("Cab Size", value: "\(booking.preferredSeater)-Seater")
                        LabeledContent("CNG", value: booking.prefersCNG ? "Yes" : "No")
                    }

                    if let notes = booking.customerNotes, !notes.isEmpty {
                        Section("Notes") {
                            Text(notes).foregroundStyle(.secondary)
                        }
                    }

                    // Cab — visible only when confirmed/completed
                    if (booking.statusEnum == .confirmed || booking.statusEnum == .completed),
                       let cab = booking.assignedCab {
                        Section("Your Cab") {
                            LabeledContent("Driver", value: cab.driverName)
                            LabeledContent("Phone", value: cab.driverPhone)
                            LabeledContent("Car Number", value: cab.licensePlate)
                        }
                    } else if booking.statusEnum == .pending {
                        Section {
                            Label("Awaiting cab assignment", systemImage: "clock")
                                .foregroundStyle(.orange)
                        }
                        Section {
                            Button(role: .destructive) {
                                Task { await cancel() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isCancelling {
                                        ProgressView()
                                    } else {
                                        Label("Cancel Booking", systemImage: "xmark.circle")
                                    }
                                    Spacer()
                                }
                            }
                            .disabled(isCancelling)
                        }
                    }
                }
            }
        }
        .navigationTitle("Booking")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { booking = try await APIClient.shared.perform("/api/bookings/my/\(bookingId)") }
        catch { self.error = error.localizedDescription }
    }

    private func cancel() async {
        isCancelling = true
        defer { isCancelling = false }
        do {
            struct Empty: Decodable {}
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/my/\(bookingId)/cancel", method: "PATCH")
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { BookingDetailView(bookingId: "preview") }
        .environment(AuthManager())
}
