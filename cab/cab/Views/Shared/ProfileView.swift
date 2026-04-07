import SwiftUI

struct ProfileView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var isLoggingOut = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Avatar + name
                if let user = authManager.currentUser {
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 54, height: 54)
                                Text(user.name.prefix(1).uppercased())
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.tint)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.name).font(.headline)
                                Text(user.isAdmin ? "Admin" : "Customer")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Account") {
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Phone", value: user.phone)
                    }
                } else {
                    Section {
                        ProgressView().frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                Section {
                    Button {
                        Task { await logout() }
                    } label: {
                        HStack {
                            if isLoggingOut { ProgressView().padding(.trailing, 4) }
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                    .disabled(isLoggingOut || isDeleting)
                }

                if authManager.role == "customer" {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Account", systemImage: "trash")
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
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All your bookings and data will be permanently removed.")
            }
        }
    }

    private func logout() async {
        isLoggingOut = true
        defer { isLoggingOut = false }
        await authManager.logout()
    }

    private func deleteAccount() async {
        isDeleting = true; errorMessage = nil
        defer { isDeleting = false }
        do { try await authManager.deleteAccount() }
        catch { errorMessage = error.localizedDescription }
    }
}

#Preview { ProfileView().environment(AuthManager()) }
