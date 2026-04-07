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

    var isEditing: Bool { cab != nil }

    private var isFormValid: Bool {
        !driverName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !driverPhone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !vehicleModel.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty &&
        !color.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Driver") {
                    TextField("Driver Name", text: $driverName)
                        .textContentType(.name)
                    TextField("Phone Number", text: $driverPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section("Vehicle") {
                    TextField("Model (e.g. Maruti Swift)", text: $vehicleModel)
                    TextField("License Plate (e.g. DL 01 AB 1234)", text: $licensePlate)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    TextField("Color", text: $color)
                        .textContentType(.none)
                }

                Section("Cab Type") {
                    Picker("Seater Capacity", selection: $seaterCapacity) {
                        Text("4-Seater").tag(4)
                        Text("6-Seater").tag(6)
                        Text("7-Seater").tag(7)
                    }

                    Toggle(isOn: $isCNG) {
                        Label("CNG Vehicle", systemImage: "leaf.fill")
                    }
                }

                if isEditing {
                    Section("Status") {
                        Toggle(isOn: $isActive) {
                            Label("Active", systemImage: "checkmark.circle.fill")
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
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    }
                }
            }
            .onAppear { populate() }
        }
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
        isSaving = true; errorMessage = nil
        defer { isSaving = false }

        struct Body: Encodable {
            let driverName, driverPhone, vehicleModel, licensePlate, color: String
            let seaterCapacity: Int
            let isCNG: Bool
            let isActive: Bool
        }

        let body = Body(
            driverName: driverName.trimmingCharacters(in: .whitespaces),
            driverPhone: driverPhone.trimmingCharacters(in: .whitespaces),
            vehicleModel: vehicleModel.trimmingCharacters(in: .whitespaces),
            licensePlate: licensePlate.trimmingCharacters(in: .whitespaces).uppercased(),
            color: color.trimmingCharacters(in: .whitespaces),
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
