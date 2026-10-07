import SwiftUI
import Supabase

struct SettingsView: View {
    // MARK: - Debug
    @State private var debugModeEnabled: Bool = DebugMode.shared.isEnabled

    // MARK: - Account
    @State private var userEmail: String = ""
    @State private var isLoadingEmail: Bool = false

    // MARK: - Alerts / State
    @State private var showSignOutAlert: Bool = false
    @State private var showEraseAlert: Bool = false
    @State private var isErasing: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        MusicShadowEmblem(size: 28)
                        Text("Settings")
                            .font(.largeTitle.bold())
                            .foregroundColor(MSTheme.primaryText)
                    }
                    Text("Manage your account and learn a bit more about Music Shadow.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.horizontal, MSTheme.Spacing.lg)
                .padding(.top, MSTheme.Spacing.sm)

                // MARK: Account
                SettingsSectionCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            MSTheme.Colors.accentPrimary.opacity(0.7),
                                            MSTheme.Colors.accentSecondary.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)
                            Image(systemName: "person.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Logged in")
                                .font(.headline)
                                .foregroundColor(MSTheme.primaryText)
                            Text(isLoadingEmail ? "Loading…" : (userEmail.isEmpty ? "Not signed in" : userEmail))
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        Spacer()
                    }

                    Divider().overlay(MSTheme.cardStroke).padding(.vertical, 4)

                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                                .font(.callout.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                                .fill(MSTheme.Colors.error.opacity(0.15))
                        )
                        .foregroundColor(MSTheme.Colors.error)
                    }
                    .buttonStyle(.plain)
                }

                if FeatureFlags.partnerEnabled {
                    // MARK: Partner
                    SettingsSectionCard(title: "Partner", subtitle: "Link with one person you trust. They only see what you choose to share.") {
                        PartnerLinkView()
                    }
                }

                // MARK: Send log (Phase 0)
                SettingsSectionCard(title: "Send log", subtitle: "Songs you've sent with a note. Fill in what happened afterward.") {
                    NavigationLink { SendLogView() } label: {
                        SettingsNavRow(
                            systemName: "paperplane",
                            title: "Open send log",
                            subtitle: "A private list on this phone"
                        )
                    }
                    .buttonStyle(.plain)
                }

                // MARK: Debug Mode
                SettingsSectionCard(title: "Debug Mode", subtitle: "Enable extra logging and show last refresh times in list views.") {
                    HStack {
                        Text("Enable debug mode")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)
                        Spacer()
                        Toggle("", isOn: $debugModeEnabled)
                            .labelsHidden()
                            .tint(MSTheme.Colors.accentPrimary)
                            .onChange(of: debugModeEnabled) { newValue in
                                DebugMode.shared.isEnabled = newValue
                            }
                    }
                }

                // MARK: Trust & transparency
                SettingsSectionCard(title: "Trust & transparency") {
                    VStack(spacing: 0) {
                        NavigationLink { HowAIWorksView() } label: {
                            SettingsNavRow(
                                systemName: "sparkles",
                                title: "How AI works",
                                subtitle: "Learn about AI reflections and how they're generated"
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(MSTheme.cardStroke).padding(.vertical, 8)

                        NavigationLink { PrivacyAndDataView() } label: {
                            SettingsNavRow(
                                systemName: "lock.shield",
                                title: "Privacy & data",
                                subtitle: "Understand your data ownership and privacy rights"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: Reset & Erase All Data
                SettingsSectionCard(title: "Reset & Erase All Data") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Permanently delete all your activations, insights, and patterns. This cannot be undone.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)

                        Button {
                            showEraseAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Erase all data")
                                    .font(.callout.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                                    .fill(MSTheme.Colors.error.opacity(0.15))
                            )
                            .foregroundColor(MSTheme.Colors.error)
                        }
                        .buttonStyle(.plain)
                        .disabled(isErasing)
                    }
                }

                // MARK: About
                SettingsSectionCard(title: "About Music Shadow") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Music Shadow helps you notice how songs land in your body, track the patterns over time, and gently surface shadow work themes through AI reflections.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)

                        Divider().overlay(MSTheme.cardStroke)

                        HStack {
                            Text("Version")
                                .font(.caption.weight(.medium))
                                .foregroundColor(MSTheme.secondaryText)
                            Spacer()
                            Text(versionString)
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                    }
                }
            }
            .padding(.vertical, MSTheme.Spacing.md)
            .padding(.horizontal, MSTheme.Spacing.lg)
        }
        .musicShadowBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserEmail()
        }
        .alert("Log Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { signOut() }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Erase All Data", isPresented: $showEraseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Erase", role: .destructive) { eraseAllData() }
        } message: {
            Text("This will permanently delete all your activations, insights, and patterns. This cannot be undone.")
        }
    }

    // MARK: - Helpers

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func loadUserEmail() {
        isLoadingEmail = true
        Task {
            let client = SupabaseClientManager.shared.client
            if let session = client.auth.currentSession {
                await MainActor.run {
                    userEmail = session.user.email ?? ""
                    isLoadingEmail = false
                }
                return
            }
            do {
                let session = try await client.auth.session
                await MainActor.run {
                    userEmail = session.user.email ?? ""
                    isLoadingEmail = false
                }
            } catch {
                await MainActor.run {
                    userEmail = ""
                    isLoadingEmail = false
                }
            }
        }
    }

    private func signOut() {
        Task {
            do {
                DataCache.shared.invalidateAll()
                try await SupabaseClientManager.shared.client.auth.signOut()
                NotificationCenter.default.post(name: .musicShadowDidLogout, object: nil)
            } catch {
                // Auth state on the server may not have been cleared, but the local
                // session is still invalid — flip into the signed-out state so the
                // user isn't stranded on a half-authed AuthView.
                NotificationCenter.default.post(name: .musicShadowDidLogout, object: nil)
            }
        }
    }

    private func eraseAllData() {
        isErasing = true
        Task {
            do {
                let client = SupabaseClientManager.shared.client
                guard let userId = client.auth.currentSession?.user.id else {
                    await MainActor.run { isErasing = false }
                    return
                }
                try await client
                    .from("song_events")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                try await client
                    .from("shadow_insights")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                DataCache.shared.invalidateAll()
                MilestoneTracker.resetMilestones()
                await MainActor.run {
                    isErasing = false
                    NotificationCenter.default.post(name: .musicShadowDataErased, object: nil)
                    HapticManager.trigger(.heavy)
                }
            } catch {
                await MainActor.run { isErasing = false }
            }
        }
    }
}

// MARK: - Section Card

private struct SettingsSectionCard<Content: View>: View {
    var title: String? = nil
    var subtitle: String? = nil
    let content: () -> Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(MSTheme.Spacing.md)
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
}

// MARK: - Nav Row

private struct SettingsNavRow: View {
    let systemName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 30, height: 30)
                Image(systemName: systemName)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(MSTheme.Colors.accentPrimary)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText)
                .accessibilityHidden(true)
        }
        .accessibleButton(label: title, hint: subtitle)
        .minimumTouchTarget(44)
    }
}

// MARK: - Shared Helpers (used by other views)

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


#Preview {
    NavigationStack {
        SettingsView()
    }
}
