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

                // Brand
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "car.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.tint)
                    }
                    Text("CabBook")
                        .font(.largeTitle.bold())
                    Text("Book your ride, hassle-free")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer().frame(height: 40)

                // Field card
                VStack(spacing: 0) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    Divider().padding(.leading, 16)
                    SecureField("Password", text: $password)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                }

                // Error
                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }

                // Button
                Button { Task { await login() } } label: {
                    Group {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Log In").fontWeight(.semibold) }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 16)

                Spacer()

                // Sign up
                Button { goSignup = true } label: {
                    HStack(spacing: 4) {
                        Text("New here?").foregroundStyle(.secondary)
                        Text("Create an account").fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 28)
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
