import SwiftUI

struct SignupView: View {

    @Environment(AuthManager.self) private var authManager

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Field card
                VStack(spacing: 0) {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    Divider().padding(.leading, 16)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    Divider().padding(.leading, 16)

                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    Divider().padding(.leading, 16)

                    SecureField("Password (min. 6 chars)", text: $password)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                }

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button { Task { await signup() } } label: {
                    Group {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Create Account").fontWeight(.semibold) }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || name.isEmpty || email.isEmpty || phone.isEmpty || password.count < 6)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .navigationTitle("Create Account")
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
