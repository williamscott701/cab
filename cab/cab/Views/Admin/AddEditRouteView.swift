import SwiftUI

struct AddEditRouteView: View {

    let route: Route?
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var from = ""
    @State private var to = ""
    @State private var routeType = "city_to_airport"
    @State private var prices: [EditablePriceEntry] = Self.defaultPrices()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let routeTypes = ["city_to_airport", "airport_to_city"]

    var isEditing: Bool { route != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    TextField("From", text: $from)
                    TextField("To", text: $to)
                    Picker("Route Type", selection: $routeType) {
                        Text("City → Airport").tag("city_to_airport")
                        Text("Airport → City").tag("airport_to_city")
                    }
                }

                Section("Price Matrix") {
                    ForEach($prices) { $entry in
                        HStack {
                            Text("\(entry.seaterCapacity)-Seater \(entry.isCNG ? "(CNG)" : "")")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.subheadline)
                            TextField("₹", value: $entry.price, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Route" : "Add Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .onAppear { populate() }
        }
    }

    private var isFormValid: Bool {
        !from.isEmpty && !to.isEmpty && prices.allSatisfy { $0.price > 0 }
    }

    private func populate() {
        guard let route else { return }
        from = route.from
        to = route.to
        routeType = route.routeType
        // Merge existing prices into the editable list
        prices = Self.defaultPrices().map { entry in
            if let existing = route.prices?.first(where: { $0.seaterCapacity == entry.seaterCapacity && $0.isCNG == entry.isCNG }) {
                return EditablePriceEntry(seaterCapacity: existing.seaterCapacity, isCNG: existing.isCNG, price: existing.price)
            }
            return entry
        }
    }

    private static func defaultPrices() -> [EditablePriceEntry] {
        [
            EditablePriceEntry(seaterCapacity: 4, isCNG: false, price: 0),
            EditablePriceEntry(seaterCapacity: 4, isCNG: true,  price: 0),
            EditablePriceEntry(seaterCapacity: 6, isCNG: false, price: 0),
            EditablePriceEntry(seaterCapacity: 6, isCNG: true,  price: 0),
            EditablePriceEntry(seaterCapacity: 7, isCNG: false, price: 0)
        ]
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        struct PriceBody: Encodable {
            let seaterCapacity: Int
            let isCNG: Bool
            let price: Double
        }
        struct Body: Encodable {
            let from, to, routeType: String
            let prices: [PriceBody]
        }

        let body = Body(
            from: from,
            to: to,
            routeType: routeType,
            prices: prices.map { PriceBody(seaterCapacity: $0.seaterCapacity, isCNG: $0.isCNG, price: $0.price) }
        )

        do {
            if let route {
                let _: Route = try await APIClient.shared.perform("/api/routes/\(route.id)", method: "PUT", body: body)
            } else {
                let _: Route = try await APIClient.shared.perform("/api/routes", method: "POST", body: body)
            }
            await onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Editable price entry

struct EditablePriceEntry: Identifiable {
    let id = UUID()
    let seaterCapacity: Int
    let isCNG: Bool
    var price: Double
}

#Preview {
    AddEditRouteView(route: nil) {}
}
