import SwiftUI

/// Top-level router. Switches between the auth flow and the role-appropriate TabView.
struct RootView: View {

    @Environment(AuthManager.self) private var authManager

    var body: some View {
        if authManager.isLoggedIn {
            if authManager.role == "admin" {
                AdminTabView()
            } else {
                CustomerTabView()
            }
        } else {
            LoginView()
        }
    }
}

// MARK: - Customer TabView

struct CustomerTabView: View {
    var body: some View {
        TabView {
            RouteListView()
                .tabItem { Label("Routes", systemImage: "map") }

            MyBookingsView()
                .tabItem { Label("My Bookings", systemImage: "list.bullet.clipboard") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
    }
}

// MARK: - Admin TabView

struct AdminTabView: View {
    var body: some View {
        TabView {
            AllBookingsView()
                .tabItem { Label("Bookings", systemImage: "list.clipboard") }

            CabListView()
                .tabItem { Label("Cabs", systemImage: "car.fill") }

            AdminRouteListView()
                .tabItem { Label("Routes", systemImage: "map.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
}
