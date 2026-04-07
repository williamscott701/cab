import SwiftUI

struct LoginView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var goSignup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Logo & heading
                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Vola Cabs")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Book your ride in seconds")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 36)

                VStack(spacing: 28) {
                    // Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("", text: $email, prompt: Text("Enter your email").foregroundStyle(.quaternary))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.emailAddress)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.tertiarySystemFill), in: .capsule)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SecureField("", text: $password, prompt: Text("Enter your password").foregroundStyle(.quaternary))
                                .textContentType(.password)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.tertiarySystemFill), in: .capsule)
                        }
                    }

                    // Error
                    if let error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Sign In button
                    Button {
                        Task { await login() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: .capsule
                    )
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.5 : 1.0)

                    // Sign up link
                    Button { goSignup = true } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(red: 0.0, green: 0.73, blue: 0.78))
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $goSignup) { SignupView() }
        }
    }

    private func login() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            struct Body: Encodable { let email, password: String }
            let r: LoginResponse = try await APIClient.shared.perform(
                "/api/auth/login", method: "POST",
                body: Body(email: email, password: password), authenticated: false)
            authManager.login(token: r.token, user: r.user)
        } catch { self.error = error.localizedDescription }
    }
}

#Preview { LoginView().environment(AuthManager()) }
