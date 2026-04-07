import SwiftUI

struct AssignCabSheet: View {

    let bookingId: String
    let onAssigned: () -> Void

    @State private var cabs: [Cab] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isAssigning = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading cabs…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to load cabs",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if cabs.isEmpty {
                    ContentUnavailableView("No Active Cabs", systemImage: "car.fill")
                } else {
                    List(cabs.filter(\.isActive)) { cab in
                        Button {
                            Task { await assign(cabId: cab.id) }
                        } label: {
                            CabRow(cab: cab)
                        }
                        .disabled(isAssigning)
                    }
                }
            }
            .navigationTitle("Assign a Cab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onAssigned() }
                }
            }
            .task { await loadCabs() }
        }
        .presentationDetents([.medium, .large])
    }

    private func loadCabs() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            cabs = try await APIClient.shared.perform("/api/cabs")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func assign(cabId: String) async {
        isAssigning = true
        defer { isAssigning = false }
        do {
            struct Body: Encodable { let cabId: String }
            let _: Booking = try await APIClient.shared.perform(
                "/api/bookings/\(bookingId)/assign",
                method: "PATCH",
                body: Body(cabId: cabId)
            )
            onAssigned()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Cab Row

struct CabRow: View {
    let cab: Cab

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cab.driverName).font(.headline)
            Text("\(cab.vehicleModel) · \(cab.licensePlate)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text("\(cab.seaterCapacity)-Seater")
                if cab.isCNG { Text("· CNG") }
                Text("· \(cab.color)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AssignCabSheet(bookingId: "preview") {}
        .environment(AuthManager())
}
