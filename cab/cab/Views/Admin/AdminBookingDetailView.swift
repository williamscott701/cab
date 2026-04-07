import SwiftUI

struct AdminBookingDetailView: View {

    let bookingId: String
    var onUpdate: (() -> Void)?

    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAssignSheet = false
    @State private var isUpdating = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage, booking == nil {
                ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                      description: Text(errorMessage))
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

                    // Customer
                    if let user = booking.customer {
                        Section("Customer") {
                            LabeledContent("Name", value: user.name)
                            LabeledContent("Phone", value: user.phone)
                            LabeledContent("Email", value: user.email)
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

                    // Assigned cab
                    if let cab = booking.assignedCab {
                        Section("Assigned Cab") {
                            LabeledContent("Driver", value: cab.driverName)
                            LabeledContent("Phone", value: cab.driverPhone)
                            LabeledContent("Car Number", value: cab.licensePlate)
                        }
                    }

                    // Error
                    if let errorMessage {
                        Section {
                            Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                    }

                    // Actions — pending
                    if booking.statusEnum == .pending {
                        Section {
                            Button {
                                showAssignSheet = true
                            } label: {
                                Label("Assign a Cab", systemImage: "car.badge.plus")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isUpdating)

                            Button(role: .destructive) {
                                Task { await updateStatus("cancelled") }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .disabled(isUpdating)
                        }
                    }

                    // Actions — confirmed
                    if booking.statusEnum == .confirmed {
                        Section {
                            Button {
                                Task { await updateStatus("completed") }
                            } label: {
                                Label("Mark Completed", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isUpdating)

                            Button(role: .destructive) {
                                Task { await updateStatus("cancelled") }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle.fill")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .disabled(isUpdating)
                        }
                    }
                }
            }
        }
        .navigationTitle("Booking Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showAssignSheet) {
            if let booking {
                AssignCabSheet(bookingId: booking.id) {
                    showAssignSheet = false
                    Task { await load() }
                    onUpdate?()
                }
            }
        }
    }

    private func load() async {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do { booking = try await APIClient.shared.perform("/api/bookings/\(bookingId)") }
        catch { errorMessage = error.localizedDescription }
    }

    private func updateStatus(_ status: String) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            struct Body: Encodable { let status: String }
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/\(bookingId)/status", method: "PATCH",
                body: Body(status: status))
            await load()
            onUpdate?()
        } catch { errorMessage = error.localizedDescription }
    }
}

#Preview {
    NavigationStack { AdminBookingDetailView(bookingId: "preview") }
        .environment(AuthManager())
}
