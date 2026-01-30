import SwiftUI
import Supabase

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isCheckingSession = true

    var body: some View {
        ZStack {
            if isLoggedIn {
                ContentView()
            } else if isCheckingSession {
                // Show loading screen during session check
                EtherealLoadingView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // MARK: - Title + tagline
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                MusicShadowEmblem(size: 28)
                                
                                Text("Music Shadow")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Text("Log the music that moves you. See the patterns underneath the emotion.")
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .padding(.top, 40)

                        // MARK: - Hero Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(MSTheme.accentGradient)
                                        .frame(width: 64, height: 64)
                                    
                                    MusicShadowEmblem(size: 34)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Your internal soundtrack")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("Songs carry memories, somatic cues, and old emotional patterns. This app helps you track them.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            Divider().background(Color.white.opacity(0.15))

                            Text("Sign in below to start tracking your emotional spikes and uncover your shadow patterns gently over time.")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                        // MARK: - EMAIL AUTH FIELDS
                        VStack(spacing: 14) {
                            // Email
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                TextField("you@example.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                SecureField("Enter password", text: $password)
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.top, 4)
                            }

                            // MARK: - AUTH BUTTONS
                            VStack(spacing: 12) {
                                Button {
                                    Task {
                                        await handleAuth(signUp: true)
                                    }
                                } label: {
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            MSTheme.accentGradient
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }

                                Button {
                                    Task {
                                        await handleAuth(signUp: false)
                                    }
                                } label: {
                                    Text("Log In")
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(24)
                }
                .musicShadowBackground()
            }

            // MARK: - LOADING OVERLAY
            if isLoading {
                EtherealLoadingOverlay()
            }
        }
        .task {
            // Show loading screen for a moment, then check session
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await checkExistingSession()
            await MainActor.run {
                isCheckingSession = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .musicShadowDidLogout)) { _ in
            isLoggedIn = false
        }
    }

    // MARK: - AUTH HANDLER
    private func handleAuth(signUp: Bool) async {
        errorMessage = nil
        isLoading = true

        do {
            let client = SupabaseClientManager.shared.client

            if signUp {
                _ = try await client.auth.signUp(email: email, password: password)
            } else {
                _ = try await client.auth.signIn(email: email, password: password)
            }

            await MainActor.run {
                isLoggedIn = true
                isLoading = false
            }

        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - SESSION CHECK
    private func checkExistingSession() async {
        let client = SupabaseClientManager.shared.client
        if client.auth.currentSession != nil {
            await MainActor.run {
                isLoggedIn = true
            }
        }
    }
}

extension Notification.Name {
    static let musicShadowDidLogout = Notification.Name("MusicShadowDidLogout")
}
