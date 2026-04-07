import SwiftUI

struct AddEditRouteView: View {

    let route: Route?
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var from = ""
    @State private var to = ""
    @State private var prices: [EditablePriceEntry] = Self.defaultPrices()
    @State private var isSaving = false
    @State private var errorMessage: String?

    var isEditing: Bool { route != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    TextField("From", text: $from)
                    TextField("To", text: $to)
                }

                Section("Price Matrix") {
                    ForEach($prices) { $entry in
                        HStack {
                            Label {
                                Text("\(entry.seaterCapacity)-Seater")
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }

                            if entry.isCNG {
                                Text("CNG")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.12), in: .capsule)
                                    .foregroundStyle(.green)
                            }

                            Spacer()

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
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
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
                        .fontWeight(.semibold)
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
            let from, to: String
            let prices: [PriceBody]
        }

        let body = Body(
            from: from,
            to: to,
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
