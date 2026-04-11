import SwiftUI

struct AdminRouteListView: View {

    @State private var routes: [Route] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false

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
                        Button("Retry") { Task { await loadRoutes() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                } else if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes Yet",
                        systemImage: "map",
                        description: Text("Tap + to add your first route.")
                    )
                } else {
                    List {
                        ForEach(routes) { route in
                            NavigationLink {
                                RouteDetailView(route: route) { await loadRoutes() }
                            } label: {
                                AdminRouteRow(route: route)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await deleteRoute(route) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Manage Routes")
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
            .task { await loadRoutes() }
            .refreshable { await loadRoutes() }
            .sheet(isPresented: $showAddSheet) {
                AddEditRouteView(route: nil) { await loadRoutes() }
            }
        }
    }

    private func loadRoutes() async {
        if routes.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do {
            routes = try await APIClient.shared.perform("/api/routes", authenticated: false)
        } catch is CancellationError {
            // View disappeared — ignore silently
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

// MARK: - Route Detail View

struct RouteDetailView: View {
    let route: Route
    var onUpdate: () async -> Void

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .background(Color(red: 0.0, green: 0.73, blue: 0.78).opacity(0.12), in: .circle)

                    VStack(spacing: 2) {
                        Text(route.from)
                            .font(.headline)
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                            Text(route.to)
                                .font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // Prices
            if let prices = route.prices, !prices.isEmpty {
                Section("Pricing") {
                    ForEach(Array(prices.enumerated()), id: \.offset) { _, p in
                        HStack {
                            Label {
                                Text("\(p.seaterCapacity)-Seater")
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.secondary)
                            }

                            if p.isCNG {
                                Text("CNG")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.12), in: .capsule)
                                    .foregroundStyle(.green)
                            }

                            Spacer()

                            Text("₹\(Int(p.price))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(red: 0.0, green: 0.73, blue: 0.78))
                        }
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

            // Actions
            Section {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Route", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label(isDeleting ? "Deleting…" : "Delete Route", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .disabled(isDeleting)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Route Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            AddEditRouteView(route: route) {
                await onUpdate()
            }
        }
        .confirmationDialog("Delete this route?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await deleteRoute() }
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func deleteRoute() async {
        isDeleting = true
        do {
            try await APIClient.shared.performVoid("/api/routes/\(route.id)", method: "DELETE")
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
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

            VStack(alignment: .leading, spacing: 1) {
                Text(route.from)
                    .font(.body.weight(.semibold))
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                    Text(route.to)
                        .font(.body.weight(.semibold))
                }
                if !priceRange.isEmpty {
                    Text(priceRange)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                        .padding(.top, 1)
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
