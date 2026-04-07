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
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.10), Color(.systemBackground)],
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
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(.tint)
                        }
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Join thousands of happy riders")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 36)

                    // Form card
                    VStack(spacing: 14) {
                        AuthField(icon: "person.fill", placeholder: "Full name", text: $name)
                            .textContentType(.name)

                        AuthField(icon: "envelope.fill", placeholder: "Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)

                        AuthField(icon: "phone.fill", placeholder: "Phone number", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)

                        AuthField(icon: "lock.fill", placeholder: "Password (min. 6 chars)", text: $password, isSecure: true)
                            .textContentType(.newPassword)

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
                            Task { await signup() }
                        } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || name.isEmpty || email.isEmpty || phone.isEmpty || password.count < 6)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(20)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.07), radius: 16, y: 4)
                    .padding(.horizontal, 20)

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(.secondary)
                            Text("Log in")
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

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
