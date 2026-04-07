import SwiftUI

struct BookingFormView: View {

    let route: Route
    @Environment(\.dismiss) private var dismiss

    @State private var travelDate = Date.now
    @State private var numberOfPeople = 1
    @State private var selectedSeater = 4
    @State private var prefersCNG = false
    @State private var customerNotes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    private var calculatedPrice: Double? {
        route.price(forSeater: selectedSeater, isCNG: prefersCNG)
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                // Route
                Section {
                    LabeledContent("From", value: route.from)
                    LabeledContent("To", value: route.to)
                }

                // Price
                Section {
                    HStack {
                        Label("Estimated Total", systemImage: "indianrupeesign.circle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let price = calculatedPrice {
                            Text("₹\(Int(price))")
                                .font(.title3.bold())
                                .foregroundStyle(.tint)
                        } else {
                            Text("Not available")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Travel details
                Section("Travel Details") {
                    DatePicker("Date", selection: $travelDate,
                               in: Date.now..., displayedComponents: .date)
                    Stepper("Passengers: \(numberOfPeople)", value: $numberOfPeople, in: 1...7)
                }

                // Cab preference
                Section("Cab Preference") {
                    Picker("Seater Capacity", selection: $selectedSeater) {
                        Text("4-Seater").tag(4)
                        Text("6-Seater").tag(6)
                        Text("7-Seater").tag(7)
                    }
                    .pickerStyle(.segmented)
                    Toggle("CNG Vehicle", isOn: $prefersCNG)
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
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                // Confirm
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting { ProgressView().scaleEffect(0.85) }
                            Text(isSubmitting ? "Booking…" : "Confirm Booking")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(calculatedPrice == nil || isSubmitting)
                }
            }
            .navigationTitle("Book a Cab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Booking Submitted!", isPresented: $didSubmit) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your booking is pending. We'll assign a cab shortly.")
            }
        }
    }

    private func submit() async {
        isSubmitting = true; errorMessage = nil
        defer { isSubmitting = false }
        do {
            let body = CreateBookingRequest(
                routeId: route.id,
                travelDate: dateFormatter.string(from: travelDate),
                numberOfPeople: numberOfPeople,
                preferredSeater: selectedSeater,
                prefersCNG: prefersCNG,
                customerNotes: customerNotes.isEmpty ? nil : customerNotes)
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings", method: "POST", body: body)
            didSubmit = true
        } catch { errorMessage = error.localizedDescription }
    }
}

#Preview {
    let route = Route(
        id: "1", from: "Delhi", to: "IGI Airport", routeType: "city_to_airport",
        prices: [
            PriceEntry(seaterCapacity: 4, isCNG: false, price: 850),
            PriceEntry(seaterCapacity: 4, isCNG: true, price: 650),
            PriceEntry(seaterCapacity: 6, isCNG: false, price: 1200),
            PriceEntry(seaterCapacity: 7, isCNG: false, price: 1400)
        ])
    BookingFormView(route: route).environment(AuthManager())
}
