import SwiftUI

/// Top-level router. Switches between the auth flow and the role-appropriate TabView.
struct RootView: View {

    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group {
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
        .animation(.default, value: authManager.isLoggedIn)
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
        .tint(Color(red: 0.0, green: 0.73, blue: 0.78))
    }
}

// MARK: - Admin TabView

struct AdminTabView: View {
    var body: some View {
        TabView {
            AllBookingsView()
                .tabItem { Label("Bookings", systemImage: "list.clipboard") }

            AdminRouteListView()
                .tabItem { Label("Routes", systemImage: "map.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(Color(red: 0.0, green: 0.73, blue: 0.78))
    }
}

#Preview {
    RootView()
        .environment(AuthManager())
}
