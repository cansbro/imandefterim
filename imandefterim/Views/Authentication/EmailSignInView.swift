import SwiftUI

struct EmailSignInView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.islamicBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                // Header
                Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                    .font(AppFont.title2)
                    .foregroundColor(.islamicTextPrimary)
                    .padding(.top, Spacing.xl)

                // Form
                VStack(spacing: Spacing.md) {
                    TextField("E-posta", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                        )

                    SecureField("Şifre", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                        )

                    if let error = errorMessage {
                        Text(error)
                            .font(AppFont.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Kayıt Ol" : "Giriş Yap")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.islamicGold)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                }
                .padding(.horizontal, Spacing.lg)

                // Toggle Mode
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                } label: {
                    Text(isSignUp ? "Zaten hesabın var mı? Giriş yap" : "Hesabın yok mu? Kayıt ol")
                        .font(AppFont.caption)
                        .foregroundColor(.islamicTextSecondary)
                }

                Spacer()
            }
        }
    }

    private func handleAction() {
        guard !email.isEmpty, !password.isEmpty else { return }

        // Basic validation
        if password.count < 6 {
            errorMessage = "Şifre en az 6 karakter olmalıdır."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await authService.signUpWithEmail(email: email, password: password)
                } else {
                    try await authService.signInWithEmail(email: email, password: password)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
