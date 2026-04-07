import SwiftUI

struct ProfileView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var isLoggingOut = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar header
                    if let user = authManager.currentUser {
                        avatarHeader(user: user)
                    } else {
                        ProgressView()
                            .padding(.vertical, 40)
                    }

                    // Info card
                    if let user = authManager.currentUser {
                        InfoCard(title: "Account Info", icon: "person.text.rectangle.fill") {
                            LabeledValue(label: "Name", value: user.name)
                            Divider()
                            LabeledValue(label: "Email", value: user.email)
                            Divider()
                            LabeledValue(label: "Phone", value: user.phone)
                        }
                    }

                    if let errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(errorMessage).font(.callout)
                        }
                        .foregroundStyle(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Log out
                    Button {
                        Task { await logout() }
                    } label: {
                        HStack {
                            if isLoggingOut {
                                ProgressView()
                                    .padding(.trailing, 4)
                            }
                            Label("Log Out", systemImage: "arrow.backward.circle.fill")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(isLoggingOut || isDeleting)

                    // Delete account — customers only
                    if authManager.role == "customer" {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Account", systemImage: "trash.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(isLoggingOut || isDeleting)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
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

    @ViewBuilder
    private func avatarHeader(user: User) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 84, height: 84)
                Text(user.name.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
            }
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title3.bold())
                Text((user.role ?? authManager.role ?? "user").capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

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
