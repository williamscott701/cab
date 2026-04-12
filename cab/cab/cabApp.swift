import SwiftUI

@main
struct VolaCabsApp: App {

    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
        }
    }
}
