import AuthenticationServices
import GoogleSignIn
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showEmailSignIn = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background
            Color.islamicBackground
                .ignoresSafeArea()

            // Decorative Background Elements
            GeometryReader { geometry in
                Circle()
                    .fill(Color.islamicGold.opacity(0.1))
                    .frame(width: geometry.size.width * 1.5)
                    .position(x: geometry.size.width * 0.5, y: -geometry.size.height * 0.2)

                Circle()
                    .fill(Color.islamicGreen.opacity(0.05))
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)
            }
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo & Welcome Section
                VStack(spacing: 20) {
                    Image(systemName: "book.circle.fill")  // Placeholder for app icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.islamicGold)
                        .shadow(color: .islamicGold.opacity(0.3), radius: 10, x: 0, y: 5)

                    Text(Strings.App.name)
                        .font(AppFont.largeTitle)
                        .foregroundColor(.islamicBrown)

                    Text("Manevi yolculuğunuza başlayın")
                        .font(AppFont.bodyText)
                        .foregroundColor(.islamicTextSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton { request in
                        authService.handleAppleSignInRequest(request)
                    } onCompletion: { result in
                        handleAppleSignInCompletion(result)
                    }
                    .frame(height: 50)
                    .cornerRadius(12)
                    .signInWithAppleButtonStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )

                    // Google Sign In
                    Button {
                        handleGoogleSignIn()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")  // Using system image for now, ideally use Google Logo asset
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Google ile Devam Et")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    // Email Sign In
                    Button {
                        showEmailSignIn = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                            Text("E-posta ile Devam Et")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.islamicGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .islamicGreen.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)

                // Guest Sign In
                // Guest Sign In
                Button {
                    handleGuestSignIn()
                } label: {
                    Text("Misafir Olarak Devam Et")
                        .fontWeight(.semibold)
                        .foregroundColor(.islamicTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.islamicGold.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.islamicGold.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView()
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Handlers

    private func handleGoogleSignIn() {
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    try await authService.signInWithApple(authorization: authorization)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleGuestSignIn() {
        Task {
            do {
                try await authService.signInAnonymously()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
