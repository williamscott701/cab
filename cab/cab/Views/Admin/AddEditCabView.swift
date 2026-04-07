import SwiftUI

struct AddEditCabView: View {

    let cab: Cab?
    let onSave: () async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var driverName = ""
    @State private var driverPhone = ""
    @State private var vehicleModel = ""
    @State private var licensePlate = ""
    @State private var color = ""
    @State private var seaterCapacity = 4
    @State private var isCNG = false
    @State private var isActive = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let seaterOptions = [4, 6, 7]

    var isEditing: Bool { cab != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Driver") {
                    TextField("Driver Name", text: $driverName)
                    TextField("Driver Phone", text: $driverPhone)
                        .keyboardType(.phonePad)
                }

                Section("Vehicle") {
                    TextField("Vehicle Model", text: $vehicleModel)
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                    TextField("Color", text: $color)
                }

                Section("Specifications") {
                    Picker("Seater Capacity", selection: $seaterCapacity) {
                        ForEach(seaterOptions, id: \.self) { seats in
                            Text("\(seats)-Seater").tag(seats)
                        }
                    }
                    Toggle("CNG", isOn: $isCNG)
                    Toggle("Active", isOn: $isActive)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Cab" : "Add Cab")
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
        !driverName.isEmpty && !driverPhone.isEmpty && !vehicleModel.isEmpty
            && !licensePlate.isEmpty && !color.isEmpty
    }

    private func populate() {
        guard let cab else { return }
        driverName = cab.driverName
        driverPhone = cab.driverPhone
        vehicleModel = cab.vehicleModel
        licensePlate = cab.licensePlate
        color = cab.color
        seaterCapacity = cab.seaterCapacity
        isCNG = cab.isCNG
        isActive = cab.isActive
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        struct Body: Encodable {
            let driverName, driverPhone, vehicleModel, licensePlate, color: String
            let seaterCapacity: Int
            let isCNG, isActive: Bool
        }

        let body = Body(
            driverName: driverName,
            driverPhone: driverPhone,
            vehicleModel: vehicleModel,
            licensePlate: licensePlate,
            color: color,
            seaterCapacity: seaterCapacity,
            isCNG: isCNG,
            isActive: isActive
        )

        do {
            if let cab {
                let _: Cab = try await APIClient.shared.perform("/api/cabs/\(cab.id)", method: "PUT", body: body)
            } else {
                let _: Cab = try await APIClient.shared.perform("/api/cabs", method: "POST", body: body)
            }
            await onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddEditCabView(cab: nil) {}
}
