import SwiftUI

struct AdminRouteListView: View {

    @State private var routes: [Route] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var routeToEdit: Route?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading routes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if routes.isEmpty {
                    ContentUnavailableView("No Routes", systemImage: "map",
                                          description: Text("Tap + to add a route."))
                } else {
                    List {
                        ForEach(routes) { route in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(route.from) → \(route.to)").font(.headline)
                                Text(route.displayRouteType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await deleteRoute(route) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    routeToEdit = route
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Routes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
                }
            }
            .task { await loadRoutes() }
            .refreshable { await loadRoutes() }
            .sheet(isPresented: $showAddSheet) {
                AddEditRouteView(route: nil) { await loadRoutes() }
            }
            .sheet(item: $routeToEdit) { route in
                AddEditRouteView(route: route) { await loadRoutes() }
            }
        }
    }

    private func loadRoutes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            routes = try await APIClient.shared.perform("/api/routes", authenticated: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteRoute(_ route: Route) async {
        do {
            try await APIClient.shared.performVoid("/api/routes/\(route.id)", method: "DELETE")
            await loadRoutes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AdminRouteListView()
        .environment(AuthManager())
}
