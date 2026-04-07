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
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load Routes",
                        systemImage: "wifi.slash",
                        description: Text(errorMessage)
                    )
                } else if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes Yet",
                        systemImage: "map",
                        description: Text("Check back soon.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(routes) { route in
                                RouteCard(route: route) {
                                    selectedRoute = route
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
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

    private var minPrice: Int? {
        route.prices?.map(\.price).min().map { Int($0) }
    }
    private var maxPrice: Int? {
        route.prices?.map(\.price).max().map { Int($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top strip: route type badge
            HStack {
                Label(route.displayRouteType, systemImage: "arrow.triangle.swap")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
                if let lo = minPrice, let hi = maxPrice {
                    Text("₹\(lo) – ₹\(hi)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            // Route visual
            HStack(alignment: .top, spacing: 12) {
                // Timeline dots
                VStack(spacing: 0) {
                    Circle()
                        .fill(.tint)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 10, height: 10)
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 0) {
                    Text(route.from)
                        .font(.title3.weight(.semibold))
                    Spacer().frame(height: 24)
                    Text(route.to)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onBook()
                } label: {
                    Label("Book", systemImage: "arrow.right")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.07), radius: 10, y: 3)
    }
}

#Preview {
    RouteListView()
        .environment(AuthManager())
}
