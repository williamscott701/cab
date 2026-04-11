import SwiftUI

struct RouteListView: View {

    @State private var routes: [Route] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedRoute: Route?
    @State private var searchText = ""
    @State private var selectedFrom = "All"

    private var fromOptions: [String] {
        let froms = routes.map(\.from)
        return ["All"] + Array(Set(froms)).sorted()
    }

    private var filteredRoutes: [Route] {
        var list = routes
        if selectedFrom != "All" {
            list = list.filter { $0.from == selectedFrom }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.from.localizedCaseInsensitiveContains(searchText) ||
                $0.to.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView {
                        Label("Couldn't Load", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                    }
                } else {
                    List {
                        // From filter
                        if fromOptions.count > 2 {
                            Section {
                                Picker("Departure", selection: $selectedFrom) {
                                    ForEach(fromOptions, id: \.self) { city in
                                        Text(city).tag(city)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        if filteredRoutes.isEmpty {
                            ContentUnavailableView(
                                "No Routes",
                                systemImage: "map",
                                description: Text("No routes match your search.")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(filteredRoutes) { route in
                                RouteRow(route: route) { selectedRoute = route }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Routes")
            .searchable(text: $searchText, prompt: "Search destination")
            .task { await load() }
            .refreshable { await load() }
            .sheet(item: $selectedRoute) { BookingFormView(route: $0) }
        }
    }

    private func load() async {
        if routes.isEmpty { isLoading = true }
        error = nil
        defer { isLoading = false }
        do { routes = try await APIClient.shared.perform("/api/routes", authenticated: false) }
        catch is CancellationError { }
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
        return lo == hi ? "₹\(Int(lo))" : "₹\(Int(lo)) – ₹\(Int(hi))"
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
                if let p = priceRange {
                    Text(p)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                        .padding(.top, 1)
                }
            }

            Spacer()

            Button("Book", action: onBook)
                .font(.callout.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
        }
        .padding(.vertical, 4)
    }
}

#Preview { RouteListView().environment(AuthManager()) }
