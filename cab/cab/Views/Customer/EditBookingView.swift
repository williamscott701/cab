import SwiftUI

struct EditBookingView: View {

    let booking: Booking
    let onSaved: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var travelDate = Date.now
    @State private var numberOfPeople = 1
    @State private var selectedSeater = 4
    @State private var prefersCNG = false
    @State private var customerNotes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var calculatedPrice: Double? {
        booking.route?.price(forSeater: selectedSeater, isCNG: prefersCNG)
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                // Route header (read-only)
                if let route = booking.route {
                    Section {
                        HStack(spacing: 14) {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .background(Color(red: 0.0, green: 0.73, blue: 0.78).opacity(0.12), in: .rect(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(route.from)
                                    .font(.headline)
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                    Text(route.to)
                                        .font(.headline)
                                }
                            }

                            Spacer()

                            if let price = calculatedPrice {
                                Text("₹\(Int(price))")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(Color(red: 0.0, green: 0.73, blue: 0.78))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Travel details
                Section("Travel Details") {
                    DatePicker("Date", selection: $travelDate,
                               in: Date.now..., displayedComponents: .date)
                    Stepper(value: $numberOfPeople, in: 1...7) {
                        HStack {
                            Text("Passengers")
                            Spacer()
                            Text("\(numberOfPeople)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                // Cab preference
                Section("Cab Preference") {
                    Picker("Seater", selection: $selectedSeater) {
                        Text("4-Seater").tag(4)
                        Text("6-Seater").tag(6)
                        Text("7-Seater").tag(7)
                    }
                    .pickerStyle(.segmented)

                    Toggle(isOn: $prefersCNG) {
                        Label("CNG Vehicle", systemImage: "leaf.fill")
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Any special requests… (optional)",
                              text: $customerNotes, axis: .vertical)
                        .lineLimit(3...)
                }

                // Error
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                // Save
                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView().tint(.white).padding(.trailing, 6)
                            }
                            Text(isSubmitting ? "Saving…" : "Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: .capsule
                    )
                    .disabled(calculatedPrice == nil || isSubmitting)
                    .opacity(calculatedPrice == nil || isSubmitting ? 0.5 : 1.0)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Booking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        numberOfPeople = booking.numberOfPeople
        selectedSeater = booking.preferredSeater
        prefersCNG = booking.prefersCNG
        customerNotes = booking.customerNotes ?? ""

        // Parse existing travel date
        let isoFrac = ISO8601DateFormatter()
        isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFrac.date(from: booking.travelDate) { travelDate = date; return }
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: booking.travelDate) { travelDate = date; return }
        let ymd = DateFormatter()
        ymd.dateFormat = "yyyy-MM-dd"
        if let date = ymd.date(from: booking.travelDate) { travelDate = date }
    }

    private func save() async {
        isSubmitting = true; errorMessage = nil
        defer { isSubmitting = false }
        do {
            let body = UpdateBookingRequest(
                travelDate: dateFormatter.string(from: travelDate),
                numberOfPeople: numberOfPeople,
                preferredSeater: selectedSeater,
                prefersCNG: prefersCNG,
                customerNotes: customerNotes.isEmpty ? nil : customerNotes)
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/my/\(booking.id)", method: "PUT", body: body)
            await onSaved()
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
