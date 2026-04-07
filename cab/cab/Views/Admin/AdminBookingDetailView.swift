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

                        StatusHero(status: booking.statusEnum, amount: booking.totalAmount)

                        // Customer
                        if let user = booking.customer {
                            InfoCard(title: "Customer", icon: "person.fill") {
                                LabeledValue(label: "Name", value: user.name)
                                Divider()
                                LabeledValue(label: "Phone", value: user.phone)
                                Divider()
                                LabeledValue(label: "Email", value: user.email)
                            }
                        }

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
                            InfoCard(title: "Customer Notes", icon: "text.bubble.fill") {
                                Text(notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Assigned cab
                        if let cab = booking.assignedCab {
                            InfoCard(title: "Assigned Cab", icon: "car.fill") {
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
                        }

                        if let errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(errorMessage).font(.callout)
                            }
                            .foregroundStyle(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Actions
                        actionsSection(booking: booking)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemGroupedBackground))
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

    @ViewBuilder
    private func actionsSection(booking: Booking) -> some View {
        VStack(spacing: 10) {
            if booking.statusEnum == .pending {
                Button {
                    showAssignSheet = true
                } label: {
                    Label("Assign a Cab", systemImage: "car.badge.plus")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isUpdating)

                Button {
                    Task { await updateStatus("cancelled") }
                } label: {
                    Label("Cancel Booking", systemImage: "xmark.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isUpdating)
            }

            if booking.statusEnum == .confirmed {
                HStack(spacing: 10) {
                    Button {
                        Task { await updateStatus("completed") }
                    } label: {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isUpdating)

                    Button {
                        Task { await updateStatus("cancelled") }
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isUpdating)
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
