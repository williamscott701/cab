import SwiftUI

struct ProfileView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var isLoggingOut = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // User info
                Section {
                    if let user = authManager.currentUser {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Phone", value: user.phone)
                        LabeledContent("Role", value: user.role.capitalized)
                    } else {
                        ProgressView()
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                // Actions
                Section {
                    Button(role: .none) {
                        Task { await logout() }
                    } label: {
                        HStack {
                            if isLoggingOut { ProgressView().padding(.trailing, 4) }
                            Text("Log Out")
                                .foregroundStyle(.primary)
                        }
                    }
                    .disabled(isLoggingOut || isDeleting)
                }

                // Delete account — customers only
                if authManager.role == "customer" {
                    Section {
                        Button("Delete Account", role: .destructive) {
                            showDeleteConfirm = true
                        }
                        .disabled(isLoggingOut || isDeleting)
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                if authManager.currentUser == nil {
                    try? await authManager.loadCurrentUser()
                }
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func logout() async {
        isLoggingOut = true
        defer { isLoggingOut = false }
        await authManager.logout()
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }
        do {
            try await authManager.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthManager())
}
