import SwiftUI

struct RouteListView: View {

    @State private var routes: [Route] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var selectedRoute: Route?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Couldn't Load", systemImage: "wifi.slash",
                                          description: Text(error))
                } else if routes.isEmpty {
                    ContentUnavailableView("No Routes", systemImage: "map",
                                          description: Text("Check back soon."))
                } else {
                    List(routes) { route in
                        RouteRow(route: route) { selectedRoute = route }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Routes")
            .task { await load() }
            .refreshable { await load() }
            .sheet(item: $selectedRoute) { BookingFormView(route: $0) }
        }
    }

    private func load() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do { routes = try await APIClient.shared.perform("/api/routes", authenticated: false) }
        catch { self.error = error.localizedDescription }
    }
}

// MARK: - Route Row

struct RouteRow: View {
    let route: Route
    let onBook: () -> Void

    private var priceRange: String? {
        let prices = route.prices?.map(\.price) ?? []
        guard let lo = prices.min(), let hi = prices.max() else { return nil }
        return lo == hi ? "₹\(Int(lo))" : "₹\(Int(lo))–₹\(Int(hi))"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Leading icon
            Image(systemName: "arrow.triangle.swap")
                .font(.callout)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1), in: Circle())

            // Route info
            VStack(alignment: .leading, spacing: 3) {
                Text("\(route.from) → \(route.to)")
                    .font(.headline)
                if let p = priceRange {
                    Text(p)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
            }

            Spacer()

            // Book button
            Button("Book", action: onBook)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview { RouteListView().environment(AuthManager()) }
