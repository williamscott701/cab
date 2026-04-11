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
                        // Search + departure filter on one line
                        Section {
                            HStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                    TextField("Search destination", text: $searchText)
                                        .autocorrectionDisabled()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 10))

                                if fromOptions.count > 2 {
                                    Menu {
                                        ForEach(fromOptions, id: \.self) { city in
                                            Button {
                                                selectedFrom = city
                                            } label: {
                                                if selectedFrom == city {
                                                    Label(city, systemImage: "checkmark")
                                                } else {
                                                    Text(city)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(selectedFrom == "All" ? "Departure" : selectedFrom)
                                                .lineLimit(1)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedFrom == "All" ? .secondary : .tint)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedFrom == "All"
                                                ? Color(.tertiarySystemFill)
                                                : Color.accentColor.opacity(0.12),
                                            in: .rect(cornerRadius: 10)
                                        )
                                    }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
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
                    .lineLimit(1)
                Text(route.to)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
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
