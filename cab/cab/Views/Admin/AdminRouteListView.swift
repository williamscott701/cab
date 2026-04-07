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
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes Yet",
                        systemImage: "map",
                        description: Text("Tap + to add your first route.")
                    )
                } else {
                    List {
                        ForEach(routes) { route in
                            AdminRouteRow(route: route)
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
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
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

// MARK: - Admin Route Row

struct AdminRouteRow: View {
    let route: Route

    private var priceRange: String {
        let prices = route.prices?.map(\.price) ?? []
        guard let lo = prices.min(), let hi = prices.max() else { return "" }
        return "₹\(Int(lo)) – ₹\(Int(hi))"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.triangle.swap")
                    .foregroundStyle(.tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(route.from) → \(route.to)")
                    .font(.headline)
                if !priceRange.isEmpty {
                    Text(priceRange)
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdminRouteListView()
        .environment(AuthManager())
}
