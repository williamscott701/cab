import SwiftUI

struct SignupView: View {

    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    Text("Create Account")
                        .font(.title.bold())
                }
                .padding(.top, 32)

                VStack(spacing: 14) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
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
                    Task { await signup() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign Up").fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty)
                .padding(.horizontal)

                Button("Already have an account? Log In") {
                    dismiss()
                }
                .font(.callout)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Action

    private func signup() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            struct Body: Encodable { let name, email, phone, password: String }
            let response: LoginResponse = try await APIClient.shared.perform(
                "/api/auth/signup",
                method: "POST",
                body: Body(name: name, email: email, phone: phone, password: password),
                authenticated: false
            )
            authManager.login(token: response.token, user: response.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SignupView()
            .environment(AuthManager())
    }
}
