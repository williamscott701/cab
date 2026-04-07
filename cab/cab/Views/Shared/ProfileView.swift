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
                // Avatar header
                if let user = authManager.currentUser {
                    Section {
                        VStack(spacing: 12) {
                            Text(user.name.prefix(1).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: .circle
                                )

                            Text(user.name)
                                .font(.title3.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                    }

                    Section("Account") {
                        LabeledContent {
                            Text(user.email)
                        } label: {
                            Label("Email", systemImage: "envelope.fill")
                        }
                        LabeledContent {
                            Text(user.phone)
                        } label: {
                            Label("Phone", systemImage: "phone.fill")
                        }
                    }
                } else {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section("Support & Privacy") {
                    Button {
                        if let url = URL(string: "mailto:williamscott701@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    Button {
                        if let url = URL(string: "mailto:williamscott701@gmail.com?subject=Privacy%20Request") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
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
            .listStyle(.insetGrouped)
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
