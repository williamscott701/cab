import SwiftUI

struct CabListView: View {

    @State private var cabs: [Cab] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var cabToEdit: Cab?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "wifi.slash")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                } else if cabs.isEmpty {
                    ContentUnavailableView(
                        "No Cabs Yet",
                        systemImage: "car.fill",
                        description: Text("Tap + to register your first cab.")
                    )
                } else {
                    List {
                        ForEach(cabs) { cab in
                            CabRow(cab: cab)
                                .contentShape(Rectangle())
                                .onTapGesture { cabToEdit = cab }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await delete(cab) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        cabToEdit = cab
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Cabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showAddSheet) {
                AddEditCabView(cab: nil) { await load() }
            }
            .sheet(item: $cabToEdit) { cab in
                AddEditCabView(cab: cab) { await load() }
            }
        }
    }

    private func load() async {
        if cabs.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do { cabs = try await APIClient.shared.perform("/api/cabs") }
        catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }

    private func delete(_ cab: Cab) async {
        do {
            try await APIClient.shared.performVoid("/api/cabs/\(cab.id)", method: "DELETE")
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Cab Row

struct CabRow: View {
    let cab: Cab

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.fill")
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

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(cab.driverName)
                        .font(.subheadline.weight(.semibold))
                    if !cab.isActive {
                        Text("Inactive")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.12), in: .capsule)
                            .foregroundStyle(.red)
                    }
                }

                Text("\(cab.vehicleModel) · \(cab.licensePlate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text("\(cab.seaterCapacity)-Seater")
                    if cab.isCNG {
                        Text("CNG")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.12), in: .capsule)
                            .foregroundStyle(.green)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CabListView()
        .environment(AuthManager())
}
