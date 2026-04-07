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
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                    Text("CabBook")
                        .font(.largeTitle.bold())
                    Text("Book your ride")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await login() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Log In").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal)

                Button("Don't have an account? Sign Up") {
                    showSignup = true
                }
                .font(.callout)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
        }
    }

    // MARK: - Action

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

#Preview {
    LoginView()
        .environment(AuthManager())
}
