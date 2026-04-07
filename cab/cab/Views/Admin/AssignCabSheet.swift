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
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "car.badge.gearshape")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .background(Color(red: 0.0, green: 0.73, blue: 0.78).opacity(0.12), in: .circle)

                        Text("Assign a Cab")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

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
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    Button {
                        Task { await assign() }
                    } label: {
                        HStack {
                            Spacer()
                            if isAssigning {
                                ProgressView().tint(.white)
                            } else {
                                Text("Confirm Assignment")
                                    .fontWeight(.semibold)
                            }
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
                    .disabled(!isFormValid || isAssigning)
                    .opacity(!isFormValid || isAssigning ? 0.5 : 1.0)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
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
        .presentationDetents([.medium, .large])
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

#Preview {
    AssignCabSheet(bookingId: "preview") {}
        .environment(AuthManager())
}
