import SwiftUI

struct BookingDetailView: View {

    let bookingId: String

    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isCancelling = false
    @State private var showEditSheet = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error {
                ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                      description: Text(error))
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
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(headerColor)
                                Text(booking.formattedDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("₹\(Int(booking.totalAmount))")
                                .font(.system(.title3, design: .rounded, weight: .bold))
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

                    // Trip Details
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

                    // Driver info
                    if (booking.statusEnum == .confirmed || booking.statusEnum == .completed),
                       let name = booking.driverName {
                        Section("Your Driver") {
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
                    } else if booking.statusEnum == .pending {
                        Section {
                            HStack {
                                Image(systemName: "clock.badge.questionmark")
                                    .foregroundStyle(.orange)
                                Text("Awaiting cab assignment")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Button {
                                showEditSheet = true
                            } label: {
                                Label("Edit Booking", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.medium)
                            }
                        }

                        Section {
                            Button(role: .destructive) {
                                Task { await cancel() }
                            } label: {
                                Label("Cancel Booking", systemImage: "xmark.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(isCancelling)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Booking")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showEditSheet) {
            if let booking {
                EditBookingView(booking: booking) {
                    await load()
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
        isLoading = true; error = nil
        defer { isLoading = false }
        do { booking = try await APIClient.shared.perform("/api/bookings/my/\(bookingId)") }
        catch { self.error = error.localizedDescription }
    }

    private func cancel() async {
        isCancelling = true
        defer { isCancelling = false }
        do {
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
