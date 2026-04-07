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

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Route summary header
                    routeSummaryCard

                    // Price banner
                    priceBanner

                    // Travel details
                    FormSection(title: "Travel Details", icon: "calendar") {
                        DatePicker(
                            "Date",
                            selection: $travelDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                        Divider()
                        Stepper {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.secondary)
                                Text("Passengers")
                                Spacer()
                                Text("\(numberOfPeople)")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                            }
                        } onIncrement: {
                            if numberOfPeople < 7 { numberOfPeople += 1 }
                        } onDecrement: {
                            if numberOfPeople > 1 { numberOfPeople -= 1 }
                        }
                    }

                    // Cab preference
                    FormSection(title: "Cab Preference", icon: "car.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Seater Capacity")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                ForEach(seaterOptions, id: \.self) { seats in
                                    SeaterButton(
                                        seats: seats,
                                        isSelected: selectedSeater == seats,
                                        action: { selectedSeater = seats }
                                    )
                                }
                            }
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CNG Vehicle")
                                    .font(.subheadline)
                                Text("Eco-friendly · lower cost")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $prefersCNG)
                                .labelsHidden()
                        }
                    }

                    // Notes
                    FormSection(title: "Notes", icon: "text.bubble") {
                        TextField("Any special requests… (optional)", text: $customerNotes, axis: .vertical)
                            .lineLimit(3...)
                    }

                    // Error
                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage).font(.callout)
                        }
                        .foregroundStyle(.red)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Confirm button
                    Button {
                        Task { await submitBooking() }
                    } label: {
                        ZStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Confirm Booking", systemImage: "checkmark.circle.fill")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(calculatedPrice == nil || isSubmitting)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Sub-views

    private var routeSummaryCard: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Circle().fill(.tint).frame(width: 8, height: 8)
                Rectangle().fill(Color.accentColor.opacity(0.3)).frame(width: 2).frame(maxHeight: .infinity)
                Circle().fill(Color(.systemGray3)).frame(width: 8, height: 8)
            }
            .padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 12) {
                Text(route.from).font(.headline)
                Text(route.to).font(.headline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(route.displayRouteType)
                .font(.caption.weight(.medium))
                .foregroundStyle(.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.top, 8)
    }

    private var priceBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let price = calculatedPrice {
                    Text("₹\(Int(price))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.tint)
                } else {
                    Text("Not available")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint.opacity(0.2))
        }
        .padding(16)
        .background(Color.accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            let _: Booking = try await APIClient.shared.perform("/api/bookings", method: "POST", body: body)
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helpers

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct SeaterButton: View {
    let seats: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "person.fill")
                    .font(.caption)
                Text("\(seats)")
                    .font(.headline.bold())
                Text("Seater")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: isSelected)
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
