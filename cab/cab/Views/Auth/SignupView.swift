import SwiftUI

struct SignupView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    private let tealGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.78, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.82)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("", text: $name, prompt: Text("Enter your name").foregroundStyle(.quaternary))
                            .textContentType(.name)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                    }

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
                        Text("Phone Number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("", text: $phone, prompt: Text("10-digit mobile number").foregroundStyle(.quaternary))
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SecureField("", text: $password, prompt: Text("Min. 6 characters").foregroundStyle(.quaternary))
                            .textContentType(.newPassword)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.tertiarySystemFill), in: .capsule)
                    }
                }

                if let error {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await signup() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .foregroundStyle(.white)
                .background(tealGradient, in: .capsule)
                .disabled(isLoading || name.isEmpty || email.isEmpty || phone.isEmpty || password.count < 6)
                .opacity(isLoading || name.isEmpty || email.isEmpty || phone.isEmpty || password.count < 6 ? 0.5 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
    }

    private func signup() async {
        isLoading = true; error = nil
        defer { isLoading = false }
        do {
            struct Body: Encodable { let name, email, phone, password: String }
            let r: LoginResponse = try await APIClient.shared.perform(
                "/api/auth/signup", method: "POST",
                body: Body(name: name, email: email, phone: phone, password: password), authenticated: false)
            authManager.login(token: r.token, user: r.user)
        } catch { self.error = error.localizedDescription }
    }
}

#Preview { NavigationStack { SignupView().environment(AuthManager()) } }
