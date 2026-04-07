import SwiftUI

struct RouteListView: View {

    @State private var routes: [Route] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedRoute: Route?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading routes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to load routes",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if routes.isEmpty {
                    ContentUnavailableView("No Routes", systemImage: "map")
                } else {
                    List(routes) { route in
                        RouteCard(route: route) {
                            selectedRoute = route
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Available Routes")
            .task { await loadRoutes() }
            .refreshable { await loadRoutes() }
            .sheet(item: $selectedRoute) { route in
                BookingFormView(route: route)
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
}

// MARK: - Route Card

struct RouteCard: View {
    let route: Route
    let onBook: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(route.displayRouteType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.from).font(.headline)
                    Image(systemName: "arrow.down").font(.caption).foregroundStyle(.secondary)
                    Text(route.to).font(.headline)
                }
                Spacer()
                Button("Book", action: onBook)
                    .buttonStyle(.borderedProminent)
            }

            let prices = route.prices.map(\.price)
            if let lo = prices.min(), let hi = prices.max() {
                Text("From ₹\(Int(lo)) – ₹\(Int(hi))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RouteListView()
        .environment(AuthManager())
}
