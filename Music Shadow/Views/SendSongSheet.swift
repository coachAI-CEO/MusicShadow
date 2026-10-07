import SwiftUI
import UIKit

/// Phase 0 "dumb send", in two steps so it is always clear what is shared, when it goes and for how long:
///   1. Compose: the sender writes a note in their own words (optionally signs it).
///   2. Review: the exact message, what stays private, when it goes, how long it lasts.
/// Only then does the share sheet open. A completed share is logged on device for the Phase 0 numbers.
struct SendSongSheet: View {
    let songTitle: String
    let artist: String

    private enum Step { case compose, review }

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .compose
    @State private var note: String = ""
    @State private var signature: String = ""
    @State private var isPreparing = false
    @State private var reviewLink: URL?
    @State private var reviewMatched = false
    @State private var shareItems: [Any]?
    @FocusState private var noteFocused: Bool
    @AppStorage("sendSongExplainerSeen") private var explainerSeen = false
    @State private var showExplainer = false

    private var count: Int { NoteRules.scalarCount(note) }
    private var showCounter: Bool { count >= NoteRules.warnAtScalars }
    private var message: String {
        ShareMessage.build(note: note, title: songTitle, artist: artist, link: reviewLink, signature: signature)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .compose: composeView
                case .review: reviewView
                }
            }
            .background(MSTheme.bgGradient.ignoresSafeArea())
            .navigationTitle(step == .compose ? "Send this song" : "Review before sending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
                if let items = shareItems {
                    ShareSheet(items: items) { completed in
                        if completed {
                            SendLogStore.shared.add(SendLogEntry(
                                songTitle: songTitle,
                                artist: artist,
                                noteLength: count,
                                matched: reviewMatched
                            ))
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showExplainer) { explainer }
            .onAppear { if !explainerSeen { showExplainer = true } }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Step 1: compose

    private var composeView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                songHeader

                Text("Say it in your own words")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)

                TextEditor(text: $note)
                    .focused($noteFocused)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(MSTheme.primaryText)
                    .frame(minHeight: 160)
                    .padding(12)
                    .background(card)
                    .accessibilityLabel("Your note")
                    .onChange(of: note) { newValue in
                        if NoteRules.scalarCount(newValue) > NoteRules.maxScalars {
                            note = NoteRules.clamp(newValue)
                        }
                    }

                if showCounter {
                    Text("\(count) of \(NoteRules.maxScalars) characters")
                        .font(.caption)
                        .foregroundColor(count >= NoteRules.maxScalars ? MSTheme.Colors.error : MSTheme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Sign it (optional)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                    TextField("Your name", text: $signature)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .background(card)
                        .foregroundColor(MSTheme.primaryText)
                        .accessibilityLabel("Sign with a name")
                        .onChange(of: signature) { newValue in
                            if NoteRules.scalarCount(newValue) > ShareMessage.maxSignatureScalars {
                                signature = NoteRules.clamp(newValue, to: ShareMessage.maxSignatureScalars)
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Need a way in?")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                    ForEach(StarterPrompts.all, id: \.self) { prompt in
                        Button {
                            note = StarterPrompts.insert(prompt, into: note)
                            noteFocused = true
                        } label: {
                            Text(prompt)
                                .font(.footnote)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.08)))
                                .foregroundColor(MSTheme.primaryText)
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 44)
                    }
                }

                Text("Nothing is sent yet. You'll see exactly what goes out on the next screen.")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            actionBar {
                primaryButton(
                    title: isPreparing ? "Getting the song link…" : "Review",
                    enabled: NoteRules.isSendable(note) && !isPreparing,
                    busy: isPreparing
                ) {
                    Task { await goToReview() }
                }
            }
        }
    }

    // MARK: Step 2: review

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                disclosureCard(title: ShareDisclosure.whatTitle) {
                    Text(message)
                        .font(.callout)
                        .foregroundColor(MSTheme.primaryText)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Message to send: \(message)")
                    Text(ShareDisclosure.linkDescription(matched: reviewMatched))
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }

                disclosureCard(title: ShareDisclosure.notSharedTitle) {
                    Text(ShareDisclosure.notShared)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }

                disclosureCard(title: ShareDisclosure.whenTitle) {
                    Text(ShareDisclosure.when)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }

                disclosureCard(title: ShareDisclosure.howLongTitle) {
                    Text(ShareDisclosure.howLong)
                        .font(.footnote)
                        .foregroundColor(MSTheme.primaryText)
                    Text(ShareDisclosure.linkNote)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            actionBar {
                primaryButton(title: "Choose who to send to", enabled: true, busy: false) {
                    shareItems = [message]
                }
                Button {
                    step = .compose
                } label: {
                    Text("Edit")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Pieces

    private var songHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(songTitle).font(.headline).foregroundColor(MSTheme.primaryText)
            if !artist.isEmpty {
                Text(artist).font(.subheadline).foregroundColor(MSTheme.secondaryText)
            }
        }
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
            .fill(MSTheme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                .stroke(MSTheme.cardStroke, lineWidth: 1))
    }

    private func disclosureCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(card)
    }

    /// Pinned bottom bar so the main action is always on screen, whatever the scroll position.
    private func actionBar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 4) { content() }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
    }

    private func primaryButton(title: String, enabled: Bool, busy: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if busy { ProgressView().tint(.white) }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                    .fill(enabled ? MSTheme.Colors.accentPrimary : Color.white.opacity(0.12))
            )
            .foregroundColor(.white)
        }
        .disabled(!enabled)
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Send a song with your own words")
                .font(.title3.weight(.semibold))
            Text("You write a short note. Before anything goes out, you'll see the exact message: your words, the song and a link.")
            Text("Then you pick who gets it in the share sheet. It's an ordinary message, so once it's sent it can't be taken back.")
                .foregroundColor(MSTheme.secondaryText)
            Text("This test keeps a private list on your phone, not on a server, so we can learn what helps.")
                .foregroundColor(MSTheme.secondaryText)
            Button("Got it") {
                explainerSeen = true
                showExplainer = false
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg).fill(MSTheme.Colors.accentPrimary))
            .foregroundColor(.white)
        }
        .padding(24)
        .foregroundColor(MSTheme.primaryText)
        .background(MSTheme.bgGradient.ignoresSafeArea())
        .presentationDetents([.medium])
    }

    // MARK: Actions

    private func goToReview() async {
        guard NoteRules.isSendable(note) else { return }
        isPreparing = true
        let match = await ITunesSearchService.lookup(title: songTitle, artist: artist)
        reviewMatched = match?.storeURL != nil
        reviewLink = match?.storeURL ?? AppleMusicLink.searchURL(title: songTitle, artist: artist)
        isPreparing = false
        step = .review
    }
}
