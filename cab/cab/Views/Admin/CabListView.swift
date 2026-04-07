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
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if cabs.isEmpty {
                    ContentUnavailableView(
                        "No Cabs Yet",
                        systemImage: "car.fill",
                        description: Text("Tap + to add your first cab.")
                    )
                } else {
                    List {
                        ForEach(cabs) { cab in
                            CabRow(cab: cab)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await deleteCab(cab) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        cabToEdit = cab
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Manage Cabs")
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
            .task { await loadCabs() }
            .refreshable { await loadCabs() }
            .sheet(isPresented: $showAddSheet) {
                AddEditCabView(cab: nil) { await loadCabs() }
            }
            .sheet(item: $cabToEdit) { cab in
                AddEditCabView(cab: cab) { await loadCabs() }
            }
        }
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

    private func deleteCab(_ cab: Cab) async {
        do {
            try await APIClient.shared.performVoid("/api/cabs/\(cab.id)", method: "DELETE")
            await loadCabs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CabListView()
        .environment(AuthManager())
}
