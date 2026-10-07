import SwiftUI

/// Settings content for linking with one partner: make a code, enter a code, or unlink.
struct PartnerLinkView: View {
    @StateObject private var model: PartnerLinkModel
    var feedAPI: PartnerAPI

    @State private var myName = ""
    @State private var codeInput = ""
    @State private var showUnlinkConfirm = false

    @MainActor
    init(model: PartnerLinkModel? = nil, feedAPI: PartnerAPI = SupabasePartnerAPI()) {
        _model = StateObject(wrappedValue: model ?? PartnerLinkModel())
        self.feedAPI = feedAPI
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !model.isLoaded {
                ProgressView().tint(MSTheme.secondaryText)
            } else {
                switch model.state {
                case .none: unlinked
                case .invited(let code, let expiresAt): invited(code: code, expiresAt: expiresAt)
                case .paired(let name): paired(name: name)
                }
            }

            if let message = model.message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(MSTheme.Colors.error)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("partnerMessage")
            }

            Text("Your partner only sees an activation if you switch on sharing for it, and only the details you choose. Either of you can unlink at any time.")
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .task { await model.refresh() }
    }

    // MARK: - Not linked

    private var unlinked: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your name (optional)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MSTheme.secondaryText)
                TextField("How your partner sees you", text: $myName)
                    .textFieldStyle(MSTextFieldStyle())
                    .textInputAutocapitalization(.words)
                    .onChange(of: myName) { _, value in
                        if value.count > 40 { myName = String(value.prefix(40)) }
                    }
            }

            actionButton("Create an invite code", systemImage: "plus.circle", id: "createInvite") {
                Task { await model.createInvite(name: myName) }
            }

            Divider().overlay(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Have a code?")
                    .font(.caption.weight(.medium))
                    .foregroundColor(MSTheme.secondaryText)
                TextField("ABCD-EFGH", text: $codeInput)
                    .textFieldStyle(MSTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onChange(of: codeInput) { _, value in
                        let shown = PartnerCode.display(value)
                        if shown != value { codeInput = shown }
                    }
            }

            actionButton("Link with this code", systemImage: "link", id: "joinCode", enabled: PartnerCode.isComplete(codeInput)) {
                Task { await model.join(code: codeInput, name: myName) }
            }
        }
    }

    // MARK: - Invite open

    private func invited(code: String, expiresAt: Date?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Give this code to your partner")
                .font(.caption.weight(.medium))
                .foregroundColor(MSTheme.secondaryText)

            Text(PartnerCode.display(code))
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .foregroundColor(MSTheme.primaryText)
                .textSelection(.enabled)
                .accessibilityIdentifier("inviteCode")

            if let expiresAt {
                (Text("Works for ") + Text(expiresAt, style: .relative) + Text(" more"))
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }

            ShareLink(item: PartnerCode.shareMessage(code: code)) {
                buttonLabel("Share the code", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.plain)

            actionButton("Cancel this invite", systemImage: "xmark.circle", id: "cancelInvite", destructive: true) {
                Task { await model.cancelInvite() }
            }
        }
    }

    // MARK: - Linked

    private func paired(name: String?) -> some View {
        let who = (name?.isEmpty == false) ? name! : "your partner"
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(MSTheme.Colors.accentPrimary)
                Text("Linked with \(who)")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
            }
            .accessibilityElement(children: .combine)

            NavigationLink {
                PartnerFeedView(api: feedAPI, partnerName: name)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.wave.2")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(MSTheme.Colors.accentPrimary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What \(who) shares with you")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)
                        Text("Activations they chose to share")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            actionButton("Unlink", systemImage: "xmark.circle", id: "unlink", destructive: true) {
                showUnlinkConfirm = true
            }
            .confirmationDialog("Unlink from \(who)?", isPresented: $showUnlinkConfirm, titleVisibility: .visible) {
                Button("Unlink", role: .destructive) { Task { await model.unlink() } }
                Button("Keep linked", role: .cancel) {}
            } message: {
                Text("You will both stop seeing each other's shared activations right away.")
            }
        }
    }

    // MARK: - Pieces

    private func buttonLabel(_ title: String, systemImage: String, destructive: Bool = false) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title).font(.callout.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                .fill(destructive ? MSTheme.Colors.error.opacity(0.15) : Color.white.opacity(0.08))
        )
        .foregroundColor(destructive ? MSTheme.Colors.error : MSTheme.primaryText)
    }

    private func actionButton(
        _ title: String, systemImage: String, id: String,
        enabled: Bool = true, destructive: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            buttonLabel(title, systemImage: systemImage, destructive: destructive)
                .overlay(alignment: .trailing) {
                    if model.isWorking { ProgressView().tint(.white).padding(.trailing, 14) }
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled || model.isWorking)
        .opacity(enabled ? 1 : 0.5)
        .accessibilityIdentifier(id)
    }
}

/// Chooses how much of an activation a linked partner sees.
struct ShareLevelPicker: View {
    @Binding var level: ShareLevel
    var disabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("What your partner sees", selection: $level) {
                ForEach(ShareLevel.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .disabled(disabled)
            .accessibilityIdentifier("shareLevelPicker")

            Text(level.detail)
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
