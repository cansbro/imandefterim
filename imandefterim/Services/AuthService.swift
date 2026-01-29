import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import GoogleSignIn

// MARK: - Auth Service
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true

    // For Apple Sign In
    private var currentNonce: String?

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    private init() {
        // Ensure Firebase is configured before setting up listener
        DispatchQueue.main.async { [weak self] in
            self?.setupAuthStateListener()
        }

        // Fallback: if no auth state change after 3 seconds, stop loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.isLoading == true {
                print("⚠️ Auth timeout - setting isLoading to false")
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener {
            [weak self] _, user in
            DispatchQueue.main.async {
                print("🔐 Auth state changed: user = \(user?.uid ?? "nil")")
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }

    // MARK: - Current User ID
    var currentUserId: String? {
        currentUser?.uid
    }

    // MARK: - Anonymous Sign In
    func signInAnonymously() async throws {
        let result = try await FirebaseManager.shared.auth.signInAnonymously()
        try await createUserProfileIfNeeded(uid: result.user.uid)
    }

    // MARK: - Google Sign In
    @MainActor
    func signInWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let rootViewController = window.rootViewController
        else {
            return
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else {
            throw NSError(
                domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "ID Token missing"])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString)

        let authResult = try await FirebaseManager.shared.auth.signIn(with: credential)
        try await createUserProfileIfNeeded(uid: authResult.user.uid)
    }

    // MARK: - Apple Sign In
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            throw NSError(
                domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID Credential"])
        }

        guard let nonce = currentNonce else {
            throw NSError(
                domain: "AuthService", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Invalid state: A login callback was received, but no login request was sent."
                ])
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            throw NSError(
                domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(
                domain: "AuthService", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to serialize token string from data: \(appleIDToken.debugDescription)"
                ])
        }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce)

        let result = try await FirebaseManager.shared.auth.signIn(with: credential)
        try await createUserProfileIfNeeded(uid: result.user.uid)
    }

    // MARK: - Email Sign In/Up
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await FirebaseManager.shared.auth.signIn(
            withEmail: email, password: password)
        try await createUserProfileIfNeeded(uid: result.user.uid)
    }

    func signUpWithEmail(email: String, password: String) async throws {
        let result = try await FirebaseManager.shared.auth.createUser(
            withEmail: email, password: password)
        try await createUserProfileIfNeeded(uid: result.user.uid)
    }

    // MARK: - Create User Profile
    private func createUserProfileIfNeeded(uid: String) async throws {
        let userRef = FirebaseManager.shared.usersCollection.document(uid)
        let snapshot = try await userRef.getDocument()

        if !snapshot.exists {
            let userData: [String: Any] = [
                "createdAt": FieldValue.serverTimestamp(),
                "cityPlateCode": 34,  // Default: İstanbul
                "cityName": "İstanbul",
                "notificationPrefs": [
                    "prayerTimesEnabled": true,
                    "dailyVerseEnabled": true,
                ],
                "premiumStatus": false,
                "lastActiveAt": FieldValue.serverTimestamp(),
            ]
            try await userRef.setData(userData)
        } else {
            // lastActiveAt güncelle
            try await userRef.updateData([
                "lastActiveAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        try FirebaseManager.shared.auth.signOut()
    }

    // MARK: - Ensure Authenticated
    func ensureAuthenticated() async throws {
        if currentUser == nil {
            try await signInAnonymously()  // Fallback or force login? For now keep anonymous fallback if needed, or remove to force login screen
        }
    }

    // MARK: - Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
