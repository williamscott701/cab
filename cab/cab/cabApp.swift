import SwiftUI

@main
struct cabApp: App {

    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
        }
    }
}
