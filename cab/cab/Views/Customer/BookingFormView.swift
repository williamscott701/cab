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
                // Route header
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

                // Confirm
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView().tint(.white).padding(.trailing, 6)
                            }
                            Text(isSubmitting ? "Booking…" : "Confirm Booking")
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
        id: "1", from: "Delhi", to: "Jaipur",
        prices: [
            PriceEntry(seaterCapacity: 4, isCNG: false, price: 850),
            PriceEntry(seaterCapacity: 4, isCNG: true, price: 650),
            PriceEntry(seaterCapacity: 6, isCNG: false, price: 1200),
            PriceEntry(seaterCapacity: 7, isCNG: false, price: 1400)
        ])
    BookingFormView(route: route).environment(AuthManager())
}
