import SwiftUI

struct BookingFormView: View {

    let route: Route
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) private var authManager

    @State private var travelDate = Date.now
    @State private var numberOfPeople = 1
    @State private var selectedSeater = 4
    @State private var prefersCNG = false
    @State private var customerNotes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    private let seaterOptions = [4, 6, 7]

    private var calculatedPrice: Double? {
        route.price(forSeater: selectedSeater, isCNG: prefersCNG)
    }

    private var priceText: String {
        calculatedPrice.map { "₹\(Int($0))" } ?? "Not available"
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(route.from).fontWeight(.semibold)
                            Image(systemName: "arrow.down").foregroundStyle(.secondary)
                            Text(route.to).fontWeight(.semibold)
                        }
                        Spacer()
                        Text(route.displayRouteType)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Travel Details") {
                    DatePicker(
                        "Travel Date",
                        selection: $travelDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    Stepper("Passengers: \(numberOfPeople)", value: $numberOfPeople, in: 1...7)
                }

                Section("Cab Preference") {
                    Picker("Seater Capacity", selection: $selectedSeater) {
                        ForEach(seaterOptions, id: \.self) { seats in
                            Text("\(seats)-Seater").tag(seats)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("CNG Cab", isOn: $prefersCNG)
                }

                Section("Estimated Price") {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(priceText)
                            .fontWeight(.semibold)
                            .foregroundStyle(calculatedPrice == nil ? .secondary : .primary)
                    }
                }

                Section("Notes (optional)") {
                    TextField("Any special requests…", text: $customerNotes, axis: .vertical)
                        .lineLimit(3...)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Book a Cab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Confirm") {
                            Task { await submitBooking() }
                        }
                        .disabled(calculatedPrice == nil || isSubmitting)
                    }
                }
            }
            .alert("Booking Confirmed!", isPresented: $didSubmit) {
                Button("Done") { dismiss() }
            } message: {
                Text("Your booking is pending. We'll assign a cab shortly.")
            }
        }
    }

    // MARK: - Action

    private func submitBooking() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            let body = CreateBookingRequest(
                routeId: route.id,
                travelDate: dateFormatter.string(from: travelDate),
                numberOfPeople: numberOfPeople,
                preferredSeater: selectedSeater,
                prefersCNG: prefersCNG,
                customerNotes: customerNotes.isEmpty ? nil : customerNotes
            )
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings",
                method: "POST",
                body: body
            )
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let route = Route(
        id: "1",
        from: "Delhi",
        to: "IGI Airport",
        routeType: "city_to_airport",
        prices: [
            PriceEntry(seaterCapacity: 4, isCNG: false, price: 850),
            PriceEntry(seaterCapacity: 4, isCNG: true, price: 650),
            PriceEntry(seaterCapacity: 6, isCNG: false, price: 1200),
            PriceEntry(seaterCapacity: 7, isCNG: false, price: 1400)
        ]
    )
    BookingFormView(route: route)
        .environment(AuthManager())
}
