import SwiftUI

struct LoginView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.12), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Hero
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 96, height: 96)
                                Image(systemName: "car.fill")
                                    .font(.system(size: 42, weight: .medium))
                                    .foregroundStyle(.tint)
                            }
                            Text("CabBook")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text("Your ride, your way")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 48)

                        // Form card
                        VStack(spacing: 16) {
                            AuthField(icon: "envelope.fill", placeholder: "Email address", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            AuthField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

                            if let errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(errorMessage)
                                        .font(.callout)
                                }
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button {
                                Task { await login() }
                            } label: {
                                ZStack {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Log In")
                                            .fontWeight(.semibold)
                                            .font(.body)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(20)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.07), radius: 16, y: 4)
                        .padding(.horizontal, 20)

                        // Sign up link
                        Button {
                            showSignup = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("New here?")
                                    .foregroundStyle(.secondary)
                                Text("Create an account")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                            }
                            .font(.callout)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            struct Body: Encodable { let email, password: String }
            let response: LoginResponse = try await APIClient.shared.perform(
                "/api/auth/login",
                method: "POST",
                body: Body(email: email, password: password),
                authenticated: false
            )
            authManager.login(token: response.token, user: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Auth Field

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LoginView()
        .environment(AuthManager())
}
