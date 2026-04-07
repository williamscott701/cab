import SwiftUI

struct AssignCabSheet: View {

    let bookingId: String
    let onAssigned: () -> Void

    @State private var cabs: [Cab] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isAssigning = false
    @State private var assigningId: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading cabs…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if cabs.filter(\.isActive).isEmpty {
                    ContentUnavailableView(
                        "No Active Cabs",
                        systemImage: "car.fill",
                        description: Text("Add cabs from the Cabs tab.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(cabs.filter(\.isActive)) { cab in
                                CabSelectionCard(
                                    cab: cab,
                                    isAssigning: assigningId == cab.id
                                ) {
                                    Task { await assign(cabId: cab.id) }
                                }
                                .disabled(isAssigning)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
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
        assigningId = cabId
        defer { isAssigning = false; assigningId = nil }
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

// MARK: - Cab Selection Card

struct CabSelectionCard: View {
    let cab: Cab
    let isAssigning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(cab.driverName)
                        .font(.headline)
                    Text("\(cab.vehicleModel) · \(cab.licensePlate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Label("\(cab.seaterCapacity)-Seater", systemImage: "person.2.fill")
                        if cab.isCNG {
                            Label("CNG", systemImage: "leaf.fill")
                                .foregroundStyle(.green)
                        }
                        Text("· \(cab.color)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if isAssigning {
                    ProgressView()
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                        .foregroundStyle(.tint)
                }
            }
            .padding(14)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cab Row (for CabListView)

struct CabRow: View {
    let cab: Cab

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cab.isActive ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
                    .frame(width: 44, height: 44)
                Image(systemName: "car.fill")
                    .foregroundStyle(cab.isActive ? Color.accentColor : Color.secondary)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(cab.driverName).font(.headline)
                    if !cab.isActive {
                        Text("Inactive")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                Text("\(cab.vehicleModel) · \(cab.licensePlate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label("\(cab.seaterCapacity)-Seater", systemImage: "person.2.fill")
                    if cab.isCNG { Label("CNG", systemImage: "leaf.fill").foregroundStyle(.green) }
                    Text("· \(cab.color)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AssignCabSheet(bookingId: "preview") {}
        .environment(AuthManager())
}
