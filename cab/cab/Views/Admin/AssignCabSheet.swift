import SwiftUI

struct AssignCabSheet: View {

    let bookingId: String
    let onAssigned: () -> Void

    @State private var driverName = ""
    @State private var driverPhone = ""
    @State private var licensePlate = ""
    @State private var isAssigning = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !driverName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !driverPhone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !licensePlate.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Driver Details") {
                    TextField("Driver Name", text: $driverName)
                        .textContentType(.name)
                    TextField("Phone Number", text: $driverPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section("Vehicle") {
                    TextField("Car Number (e.g. DL 01 AB 1234)", text: $licensePlate)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                Section {
                    Button {
                        Task { await assign() }
                    } label: {
                        HStack(spacing: 8) {
                            if isAssigning { ProgressView().scaleEffect(0.85) }
                            Text(isAssigning ? "Assigning…" : "Confirm Assignment")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || isAssigning)
                }
            }
            .navigationTitle("Assign Cab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onAssigned() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func assign() async {
        isAssigning = true
        defer { isAssigning = false }
        errorMessage = nil
        do {
            struct Body: Encodable { let driverName, driverPhone, licensePlate: String }
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/\(bookingId)/assign", method: "PATCH",
                body: Body(
                    driverName: driverName.trimmingCharacters(in: .whitespaces),
                    driverPhone: driverPhone.trimmingCharacters(in: .whitespaces),
                    licensePlate: licensePlate.trimmingCharacters(in: .whitespaces).uppercased()
                )
            )
            onAssigned()
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Cab Row (used in CabListView)

struct CabRow: View {
    let cab: Cab

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(cab.driverName).font(.headline)
                if !cab.isActive {
                    Text("Inactive")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
            Text("\(cab.licensePlate) · \(cab.driverPhone)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AssignCabSheet(bookingId: "preview") {}
        .environment(AuthManager())
}
