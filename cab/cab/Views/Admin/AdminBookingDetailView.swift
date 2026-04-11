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
                List {
                    // Header card
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: headerIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(headerColor)
                                .frame(width: 40, height: 40)
                                .background(headerColor.opacity(0.12), in: .circle)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(booking.statusEnum.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(headerColor)
                                Text(booking.formattedDate)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("₹\(Int(booking.totalAmount))")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                        }
                    }

                    // Customer
                    if let user = booking.customer {
                        Section("Customer") {
                            LabeledContent {
                                Text(user.name)
                            } label: {
                                Label("Name", systemImage: "person.fill")
                            }
                            LabeledContent {
                                Text(user.phone)
                            } label: {
                                Label("Phone", systemImage: "phone.fill")
                            }
                            LabeledContent {
                                Text(user.email)
                            } label: {
                                Label("Email", systemImage: "envelope.fill")
                            }
                        }
                    }

                    // Route
                    if let route = booking.route {
                        Section("Route") {
                            LabeledContent {
                                Text(route.from)
                            } label: {
                                Label("From", systemImage: "location.circle")
                            }
                            LabeledContent {
                                Text(route.to)
                            } label: {
                                Label("To", systemImage: "mappin.circle")
                            }
                        }
                    }

                    // Trip details
                    Section("Trip Details") {
                        LabeledContent {
                            Text(booking.formattedDate)
                        } label: {
                            Label("Date", systemImage: "calendar")
                        }
                        LabeledContent {
                            Text("\(booking.numberOfPeople)")
                        } label: {
                            Label("Passengers", systemImage: "person.2")
                        }
                        LabeledContent {
                            Text("\(booking.preferredSeater)-Seater")
                        } label: {
                            Label("Cab Size", systemImage: "car")
                        }
                        if booking.prefersCNG {
                            LabeledContent {
                                Text("Yes")
                            } label: {
                                Label("CNG", systemImage: "leaf.fill")
                            }
                        }
                    }

                    if let notes = booking.customerNotes, !notes.isEmpty {
                        Section("Notes") {
                            Text(notes).foregroundStyle(.secondary)
                        }
                    }

                    // Assigned driver
                    if let name = booking.driverName {
                        Section("Assigned Driver") {
                            LabeledContent {
                                Text(name)
                            } label: {
                                Label("Name", systemImage: "person.fill")
                            }
                            if let phone = booking.driverPhone {
                                LabeledContent {
                                    Text(phone)
                                } label: {
                                    Label("Phone", systemImage: "phone.fill")
                                }
                            }
                            if let plate = booking.licensePlate {
                                LabeledContent {
                                    Text(plate)
                                } label: {
                                    Label("Car Number", systemImage: "car.fill")
                                }
                            }
                        }
                    }

                    // Error
                    if let errorMessage {
                        Section {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.subheadline)
                        }
                    }

                    // Actions — pending
                    if booking.statusEnum == .pending {
                        Section {
                            Button {
                                showAssignSheet = true
                            } label: {
                                Label("Assign Cab", systemImage: "car.badge.gearshape")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.medium)
                            }
                            .disabled(isUpdating)

                            Button(role: .destructive) {
                                Task { await updateStatus("cancelled") }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
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
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.medium)
                            }
                            .tint(.green)
                            .disabled(isUpdating)

                            Button(role: .destructive) {
                                Task { await updateStatus("cancelled") }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(isUpdating)
                        }
                    }
                }
                .listStyle(.insetGrouped)
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

    private var headerIcon: String {
        switch booking?.statusEnum ?? .pending {
        case .pending:   return "clock.fill"
        case .confirmed: return "car.fill"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    private var headerColor: Color {
        switch booking?.statusEnum ?? .pending {
        case .pending:   return .orange
        case .confirmed: return .blue
        case .completed: return .green
        case .cancelled: return .secondary
        }
    }

    private func load() async {
        if booking == nil { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do { booking = try await APIClient.shared.perform("/api/bookings/\(bookingId)") }
        catch is CancellationError { }
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
