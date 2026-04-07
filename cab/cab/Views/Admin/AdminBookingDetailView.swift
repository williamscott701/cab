import SwiftUI

struct AdminBookingDetailView: View {

    let bookingId: String
    var onUpdate: (() -> Void)?

    @State private var booking: Booking?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAssignSheet = false
    @State private var isUpdating = false

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
                        HStack {
                            Spacer()
                            StatusBadge(status: booking.statusEnum)
                            Spacer()
                        }

                        // Customer info
                        if let user = booking.customer {
                            InfoCard(title: "Customer") {
                                LabeledValue(label: "Name", value: user.name)
                                LabeledValue(label: "Phone", value: user.phone)
                                LabeledValue(label: "Email", value: user.email)
                            }
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
                            LabeledValue(label: "Amount", value: "₹\(Int(booking.totalAmount))")
                        }

                        if let notes = booking.customerNotes, !notes.isEmpty {
                            InfoCard(title: "Customer Notes") {
                                Text(notes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Assigned cab
                        if let cab = booking.assignedCab {
                            InfoCard(title: "Assigned Cab") {
                                LabeledValue(label: "Driver", value: cab.driverName)
                                LabeledValue(label: "Phone", value: cab.driverPhone)
                                LabeledValue(label: "Vehicle", value: cab.vehicleModel)
                                LabeledValue(label: "Plate", value: cab.licensePlate)
                                LabeledValue(label: "Color", value: cab.color)
                            }
                        }

                        // Assign button — only when pending
                        if booking.statusEnum == .pending {
                            Button {
                                showAssignSheet = true
                            } label: {
                                Label("Assign Cab", systemImage: "car.badge.plus")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }

                        // Status update — confirmed → completed or cancelled
                        if booking.statusEnum == .confirmed {
                            HStack(spacing: 12) {
                                Button {
                                    Task { await updateStatus("completed") }
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(isUpdating)

                                Button {
                                    Task { await updateStatus("cancelled") }
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                                .disabled(isUpdating)
                            }
                            .padding(.horizontal)
                        }

                        // Allow cancellation from pending too
                        if booking.statusEnum == .pending {
                            Button {
                                Task { await updateStatus("cancelled") }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .padding(.horizontal)
                            .disabled(isUpdating)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Booking Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBooking() }
        .sheet(isPresented: $showAssignSheet) {
            if let booking {
                AssignCabSheet(bookingId: booking.id) {
                    showAssignSheet = false
                    Task { await loadBooking() }
                    onUpdate?()
                }
            }
        }
    }

    private func loadBooking() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            booking = try await APIClient.shared.perform("/api/bookings/\(bookingId)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateStatus(_ status: String) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            struct Body: Encodable { let status: String }
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/\(bookingId)/status",
                method: "PATCH",
                body: Body(status: status)
            )
            await loadBooking()
            onUpdate?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AdminBookingDetailView(bookingId: "preview")
    }
    .environment(AuthManager())
}
