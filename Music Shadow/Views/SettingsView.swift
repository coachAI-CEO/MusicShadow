import SwiftUI
import Supabase

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("username") private var username = ""
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = true
    @AppStorage("partnerSharingEnabled") private var partnerSharingEnabled = false

    @State private var userEmail: String = ""
    @State private var showSignOutAlert = false
    @State private var showFeedbackSheet = false
    @State private var showOnboarding = false
    @State private var isLoadingEmail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MSTheme.Spacing.lg) {
                    SettingsHeroCard(
                        username: username.isEmpty ? "Welcome back" : username,
                        email: isLoadingEmail ? "Loading email..." : (userEmail.isEmpty ? "Not set" : userEmail)
                    )

                    SettingsCard(title: "Account") {
                        SettingsRow(iconName: "person.crop.circle", title: "Username") {
                            TextField("Username", text: $username)
                                .textFieldStyle(MSTextFieldStyle())
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                        }
                        SettingsDivider()
                        SettingsRow(iconName: "envelope", title: "Email") {
                            if isLoadingEmail {
                                ProgressView()
                            } else {
                                Text(userEmail.isEmpty ? "Not set" : userEmail)
                                    .foregroundColor(MSTheme.secondaryText)
                            }
                        }
                        SettingsDivider()
                        SettingsButtonRow(
                            iconName: "rectangle.portrait.and.arrow.right",
                            title: "Sign Out",
                            isDestructive: true
                        ) {
                            showSignOutAlert = true
                        }
                    }

                    SettingsCard(title: "Data & Privacy") {
                        SettingsToggleRow(iconName: "moon.fill", title: "Dark Mode", isOn: $isDarkMode)
                    }

                    SettingsCard(title: "Partner Sharing") {
                        SettingsToggleRow(iconName: "hand.raised.fill", title: "Allow Partner Sharing", isOn: $partnerSharingEnabled)
                    }

                    SettingsCard(title: "Notifications") {
                        SettingsToggleRow(iconName: "bell.fill", title: "Enable Notifications", isOn: $isNotificationsEnabled)
                    }

                    SettingsCard(title: "About") {
                        SettingsRow(iconName: "info.circle", title: "Version") {
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        SettingsDivider()
                        SettingsButtonRow(iconName: "star.fill", title: "Rate App") {
                            requestAppReview()
                        }
                    }

                    SettingsCard(title: "Support") {
                        SettingsButtonRow(iconName: "envelope.fill", title: "Send Feedback") {
                            showFeedbackSheet = true
                        }
                    }
                }
                .padding(.vertical, MSTheme.Spacing.lg)
                .padding(.horizontal, MSTheme.Spacing.lg)
            }
            .musicShadowBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView()
        }
        .onAppear {
            loadUserEmail()
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private func loadUserEmail() {
        isLoadingEmail = true
        Task {
            let client = SupabaseClientManager.shared.client
            if let session = client.auth.currentSession {
                DispatchQueue.main.async {
                    userEmail = session.user.email ?? ""
                    isLoadingEmail = false
                }
                return
            }
            do {
                let session = try await client.auth.session
                DispatchQueue.main.async {
                    userEmail = session.user.email ?? ""
                    isLoadingEmail = false
                }
            } catch {
                DispatchQueue.main.async {
                    userEmail = "Not signed in"
                    isLoadingEmail = false
                }
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await SupabaseClientManager.shared.client.auth.signOut()
                NotificationCenter.default.post(name: .showOnboarding, object: nil)
            } catch {
                // Handle error if needed
            }
        }
    }

    private func requestAppReview() {
        // Implementation for app review request
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MSTheme.Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
            content()
        }
        .padding(.vertical, MSTheme.Spacing.md)
        .padding(.horizontal, MSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                .fill(MSTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                .stroke(MSTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct SettingsRow<Content: View>: View {
    let iconName: String
    let title: String
    let content: () -> Content

    init(iconName: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.iconName = iconName
        self.title = title
        self.content = content
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(systemName: iconName)
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
            Spacer()
            content()
        }
    }
}

struct SettingsRowContent: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundColor(MSTheme.secondaryText)
    }
}

struct SettingsButtonRow: View {
    let iconName: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIconBadge(systemName: iconName, isDestructive: isDestructive)
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(isDestructive ? MSTheme.Colors.error : MSTheme.primaryText)
                Spacer()
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsToggleRow: View {
    let iconName: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(systemName: iconName)
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(MSTheme.Colors.accentPrimary)
        }
    }
}

struct MSTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                    .stroke(MSTheme.cardStroke, lineWidth: 1)
            )
            .foregroundColor(MSTheme.primaryText)
    }
}

extension Notification.Name {
    static let showOnboarding = Notification.Name("showOnboarding")
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $feedbackText)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                            .fill(MSTheme.Colors.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
                Spacer()
            }
            .padding(MSTheme.Spacing.lg)
            .musicShadowBackground()
            .navigationTitle("Send Feedback")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        // Handle sending feedback
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(MSTheme.cardStroke)
            .frame(height: 1)
            .opacity(0.6)
    }
}

private struct SettingsIconBadge: View {
    let systemName: String
    var isDestructive: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 30, height: 30)
            Image(systemName: systemName)
                .font(.footnote.weight(.semibold))
                .foregroundColor(isDestructive ? MSTheme.Colors.error : MSTheme.Colors.accentPrimary)
        }
    }
}

private struct SettingsHeroCard: View {
    let username: String
    let email: String

    var body: some View {
        HStack(spacing: MSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                MSTheme.Colors.accentPrimary.opacity(0.6),
                                MSTheme.Colors.accentSecondary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: "person.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(username)
                    .font(.headline)
                    .foregroundColor(MSTheme.primaryText)
                Text(email)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.vertical, MSTheme.Spacing.md)
        .padding(.horizontal, MSTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                .fill(MSTheme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                .stroke(MSTheme.cardStroke, lineWidth: 1)
        )
    }
}
