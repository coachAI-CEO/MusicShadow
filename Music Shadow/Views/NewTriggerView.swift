import SwiftUI
import Supabase

// MARK: - Enums

enum BodyLocation: String, CaseIterable, Identifiable {
    case chest, throat, gut, head, limbs, wholeBody, numb
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .throat: return "Throat"
        case .gut: return "Gut"
        case .head: return "Head"
        case .limbs: return "Arms / legs"
        case .wholeBody: return "Whole body"
        case .numb: return "Numb / blank"
        }
    }

    var emoji: String {
        switch self {
        case .chest: return "💓"
        case .head: return "🧠"
        case .gut: return "🌀"
        case .throat: return "🗣️"
        case .limbs: return "🦵"
        case .wholeBody: return "🧍"
        case .numb: return "🧊"
        }
    }
}

enum SomaticType: String, CaseIterable, Identifiable {
    case tight, heavy, burning, numb, buzzing, urgeCry, urgeScream, collapse
    var id: String { rawValue }

    func displayName(for valence: TriggerValence) -> String {
        switch valence {
        case .shadow:
            switch self {
            case .tight: return "Tight / clenched"
            case .heavy: return "Heavy"
            case .burning: return "Burning"
            case .numb: return "Numb"
            case .buzzing: return "Buzzing"
            case .urgeCry: return "Urge to cry"
            case .urgeScream: return "Urge to scream"
            case .collapse: return "Collapse / shut down"
            }
        case .positive:
            switch self {
            case .tight: return "Charged / electric"
            case .heavy: return "Grounded / settled"
            case .burning: return "Warm / energized"
            case .numb: return "Calm / neutral"
            case .buzzing: return "Excited / buzzing"
            case .urgeCry: return "Moved to tears"
            case .urgeScream: return "Burst of energy"
            case .collapse: return "Melted / relaxed"
            }
        }
    }
}

enum ImpulseType: String, CaseIterable, Identifiable {
    case cry, scream, hide, cling, disappear, attack, nothing
    var id: String { rawValue }

    func displayName(for valence: TriggerValence) -> String {
        switch valence {
        case .shadow:
            switch self {
            case .cry: return "Cry"
            case .scream: return "Scream"
            case .hide: return "Hide / curl up"
            case .cling: return "Cling / hold on"
            case .disappear: return "Disappear"
            case .attack: return "Attack"
            case .nothing: return "Nothing"
            }
        case .positive:
            switch self {
            case .cry: return "Tear up / soften"
            case .scream: return "Sing / shout"
            case .hide: return "Turn inward"
            case .cling: return "Reach out / hug"
            case .disappear: return "Drift / float"
            case .attack: return "Move / take action"
            case .nothing: return "Just be"
            }
        }
    }
}

// MARK: - Main View

struct NewTriggerView: View {

    // MARK: - Song
    @State private var songTitle: String = ""
    @State private var artist: String = ""
    @State private var timestampSeconds: Int = 0
    @State private var lyricsSnippet: String = ""

    // MARK: - Somatic
    @State private var bodyLocation: BodyLocation = .chest
    @State private var somaticType: SomaticType = .tight
    @State private var impulse: ImpulseType = .cry
    @State private var intensity: Double = 5

    // MARK: - Valence (shadow vs positive)
    @State private var valence: TriggerValence = .shadow

    // MARK: - Partner sharing
    @State private var shareWithPartner: Bool = false

    // MARK: - Journal (guided)
    @State private var bodyReport: String = ""
    @State private var impulseReport: String = ""
    @State private var blockReport: String = ""
    @State private var echoReport: String = ""
    @State private var beliefReport: String = ""
    @State private var patternReport: String = ""
    @State private var interruptionDirective: String = ""

    // MARK: - Journal (free flow)
    @State private var freeJournal: String = ""

    // MARK: - UI State
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false
    @State private var showMilestoneCelebration: Bool = false
    @State private var milestoneCount: Int?
    @State private var showActivationResult: Bool = false
    @State private var savedActivationSummary: (song: String, artist: String, bodyLocation: String, intensityLabel: String)?
    @State private var savedEventId: UUID?
    @State private var savedActivationInsight: ShadowInsight?
    @State private var reflectionTimedOut: Bool = false
    @State private var showDiscardAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    /// True if the user has entered anything (song, journal, etc.) so we can warn before leaving.
    private var hasAnyInput: Bool {
        let song = songTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let art = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let lyrics = lyricsSnippet.trimmingCharacters(in: .whitespacesAndNewlines)
        let free = freeJournal.trimmingCharacters(in: .whitespacesAndNewlines)
        return !song.isEmpty || !art.isEmpty || !lyrics.isEmpty || timestampSeconds > 0
            || journalHasAnyContent || !free.isEmpty
    }
    
    // Form progress tracking
    private enum FormSection: Int, CaseIterable {
        case song = 0
        case somatic = 1
        case journal = 2
        case share = 3
        
        var label: String {
            switch self {
            case .song: return "Song Details"
            case .somatic: return "Body Scan"
            case .journal: return "Reflection"
            case .share: return "Final Touches"
            }
        }
    }
    
    private var currentStep: Int {
        // Auto-calculate based on what's filled out
        if !journalHasAnyContent && !freeJournal.isEmpty {
            return 3
        } else if somaticSectionComplete {
            return 3
        } else if songSectionComplete {
            return 2
        } else {
            return 1
        }
    }
    
    private var songSectionComplete: Bool {
        !songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var somaticSectionComplete: Bool {
        // Always considered complete since we have defaults
        songSectionComplete
    }
    
    private var journalHasAnyContent: Bool {
        !bodyReport.isEmpty ||
        !impulseReport.isEmpty ||
        !blockReport.isEmpty ||
        !echoReport.isEmpty ||
        !beliefReport.isEmpty ||
        !patternReport.isEmpty ||
        !interruptionDirective.isEmpty
    }


    // MARK: - Validation
    private var canSave: Bool {
        !songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New activation")
                            .font(.title2.bold())
                            .foregroundColor(MSTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)

                        Text("Note one moment where a song really landed in your body.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                    
                    // Progress indicator
                    FormProgressIndicator(
                        currentStep: currentStep,
                        totalSteps: FormSection.allCases.count,
                        stepLabels: FormSection.allCases.map { $0.label }
                    )
                    .padding(.top, 4)

                    // MARK: - SONG
                    songSection

                    // MARK: - SOMATIC
                    somaticSection

                    // MARK: - JOURNAL (GUIDED + FREE)
                    journalSection

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // SAVE BUTTON
                    Button {
                        Task {
                            await MainActor.run {
                                withAnimation {
                                    isSaving = true
                                }
                            }
                            await saveEvent()
                            await MainActor.run {
                                withAnimation {
                                    isSaving = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Save Activation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44) // Accessibility: minimum tap target
                        .padding()
                        .background(MSTheme.accentGradient)
                        .foregroundColor(MSTheme.primaryText)
                        .cornerRadius(16)
                        .opacity((canSave && !isSaving) ? 1.0 : 0.6)
                        .scaleEffect(isSaving ? 0.98 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSaving)
                    }
                    .disabled(!canSave || isSaving)
                    .accessibilityLabel(isSaving ? "Saving activation" : "Save activation")
                    .accessibilityHint("Save this music activation to your log")
                }
                .padding(24)
            }
            .musicShadowBackground()
            .navigationTitle("New activation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if showActivationResult {
                            dismiss()
                        } else if hasAnyInput {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityHint(hasAnyInput ? "Leave without saving; you may see a confirmation" : "Close new activation")
                }
            }
            // Saving overlay
            if isSaving {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Saving this moment…")
                        .foregroundColor(.white)
                        .font(.headline)

                    Text("Music Shadow is asking Gemini for a reflection on this activation.")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.65).ignoresSafeArea())
                .transition(.opacity.combined(with: .scale))
            }
            
            // Milestone celebration overlay
            if showMilestoneCelebration, let count = milestoneCount {
                MilestoneCelebrationView(milestoneCount: count) {
                    showMilestoneCelebration = false
                    Task {
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        await MainActor.run {
                            showActivationResult = true
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(999)
            }

            // Activation result overlay (after save success)
            if showActivationResult, let summary = savedActivationSummary {
                ActivationResultView(
                    song: summary.song,
                    artist: summary.artist,
                    bodyLocation: summary.bodyLocation,
                    intensityLabel: summary.intensityLabel,
                    insight: savedActivationInsight,
                    reflectionTimedOut: reflectionTimedOut
                ) {
                    showActivationResult = false
                    savedActivationInsight = nil
                    savedEventId = nil
                    reflectionTimedOut = false
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: .navigateToPatternsView, object: nil)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(1000)
                .task(id: showActivationResult) {
                    guard showActivationResult, let eventId = savedEventId else { return }
                    await fetchInsightForResultScreen(eventId: eventId)
                }
            }

            // Themed discard confirmation (replaces system alert)
            if showDiscardAlert {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { showDiscardAlert = false }
                    VStack(spacing: 20) {
                        Text("You sure? Activation not saved.")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(MSTheme.Colors.primaryText)
                            .multilineTextAlignment(.center)
                        Text("Your activation has not been saved. Leave anyway?")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        HStack(spacing: 12) {
                            Button {
                                showDiscardAlert = false
                            } label: {
                                Text("Cancel")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(MSTheme.Colors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.white.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                            Button {
                                showDiscardAlert = false
                                dismiss()
                            } label: {
                                Text("Leave")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(MSTheme.Colors.error.opacity(0.9))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 280)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(MSTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(MSTheme.Colors.cardStroke, lineWidth: 1)
                            )
                    )
                }
                .zIndex(1001)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSaving)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMilestoneCelebration)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showActivationResult)
        .preferredColorScheme(.dark)
    }

    // MARK: - SONG SECTION

    private var songSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Song")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            VStack(alignment: .leading, spacing: 8) {
                // Artist
                VStack(alignment: .leading, spacing: 4) {
                    Text("Artist")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    TextField("Artist", text: $artist)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }

                // Song Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    TextField("Song title", text: $songTitle)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }

                // Optional: lyrics or line that hit
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("Lyrics or line that hit you")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                        Text("(optional)")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                    }
                    TextField("Paste a line or snippet so the reflection can link it to your activation", text: $lyricsSnippet, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }

            // Timestamp mini-player
            VStack(alignment: .leading, spacing: 8) {
                Text("Spike time in the song")
                    .foregroundColor(MSTheme.secondaryText)
                    .font(.caption)

                Text(
                    String(
                        format: "%d:%02d",
                        timestampSeconds / 60,
                        timestampSeconds % 60
                    )
                )
                .foregroundColor(MSTheme.primaryText)
                .font(.title3.monospacedDigit())
                .padding(.bottom, 4)

                Slider(
                    value: Binding(
                        get: { Double(timestampSeconds) },
                        set: { timestampSeconds = Int($0) }
                    ),
                    in: 0...1200,
                    step: 1
                )
                .tint(.purple.opacity(0.9))

                HStack(spacing: 16) {
                    Button {
                        timestampSeconds = max(0, timestampSeconds - 10)
                    } label: {
                        HStack {
                            Image(systemName: "backward.fill")
                            Text("-10s")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }

                    Button {
                        timestampSeconds = min(1200, timestampSeconds + 10)
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("+10s")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
            }
        }
        .shadowCard()
    }

    // MARK: - SOMATIC SECTION

    private var somaticSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Somatic check-in")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text(
                valence == .shadow
                ? "Where did this song land when it spiked something hard?"
                : "Where did this song land when it opened or lifted you?"
            )
            .font(.caption)
            .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            .animation(.easeInOut(duration: 0.2), value: valence)

            // Valence selector
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square")
                        .foregroundColor(.purple.opacity(0.9))
                    Text("What kind of activation was this?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }

                Picker("", selection: $valence) {
                    Text("Shadow spike").tag(TriggerValence.shadow)
                    Text("Positive hit").tag(TriggerValence.positive)
                }
                .pickerStyle(.segmented)
                .tint(.purple)

                Text(
                    valence == .shadow
                    ? "Shadow spike: when the song hits an old wound, fear, or shame."
                    : "Positive hit: when the song opens you, softens, or uplifts."
                )
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.top, 2)
            }

            // Body location chips
            HStack(spacing: 6) {
                Image(systemName: "figure.arms.open")
                    .foregroundColor(.pink.opacity(0.9))
                Text("Body location")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BodyLocation.allCases) { loc in
                        somaticChip(
                            title: "\(loc.emoji) \(loc.displayName)",
                            isSelected: loc == bodyLocation
                        ) {
                            bodyLocation = loc
                        }
                    }
                }
            }

            // Sensation chips
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue.opacity(0.9))
                Text("Sensation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SomaticType.allCases) { t in
                        somaticChip(
                            title: t.displayName(for: valence),
                            isSelected: t == somaticType
                        ) {
                            somaticType = t
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: valence)
            }

            // Impulse chips
            HStack(spacing: 6) {
                Image(systemName: "figure.run")
                    .foregroundColor(.orange.opacity(0.9))
                Text("Body's impulse")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ImpulseType.allCases) { i in
                        somaticChip(
                            title: i.displayName(for: valence),
                            isSelected: i == impulse
                        ) {
                            impulse = i
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: valence)
            }

            // Intensity slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(MSTheme.accentColor)
                    Text("Intensity (1–10)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Spacer()

                    Text("\(Int(intensity))/10")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }

                Slider(value: $intensity, in: 1...10, step: 1)
                    .tint(.blue)

                HStack {
                    Text("Soft")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    Spacer()
                    Text("Overwhelming")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                }

                Text(
                    valence == .shadow
                    ? "Higher numbers = more intense, overwhelming, or flooded."
                    : "Higher numbers = more intense, buzzing, or wide-open."
                )
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                .padding(.top, 2)
                .animation(.easeInOut(duration: 0.2), value: valence)
            }
            .padding(.top, 8)

            // Partner sharing toggle
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.wave.2")
                        .foregroundColor(.purple.opacity(0.9))
                    Text("Share with partner")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }

                Toggle(
                    isOn: $shareWithPartner
                ) {
                    Text("Include this activation in your partner summary.")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))
            }
            .padding(.top, 8)
        }
        .shadowCard()
        .animation(.easeInOut(duration: 0.2), value: valence)
    }

    private func somaticChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                            ? AnyShapeStyle(MSTheme.accentGradient)
                            : AnyShapeStyle(Color.white.opacity(0.06))
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.white.opacity(0.9) : MSTheme.cardStroke,
                            lineWidth: isSelected ? 1.2 : 1
                        )
                )
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - JOURNAL SECTION

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Journal")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Move through the prompts, then let anything else spill out below.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            // Guided prompts
            VStack(alignment: .leading, spacing: 8) {
                journalField(
                    placeholder: "What did your body do?",
                    text: $bodyReport
                )
                journalField(
                    placeholder: "What did you want to do?",
                    text: $impulseReport
                )
                journalField(
                    placeholder: "What got in the way?",
                    text: $blockReport
                )
                journalField(
                    placeholder: "What you usually do in moments like this",
                    text: $patternReport
                )
                journalField(
                    placeholder: "Belief that showed up",
                    text: $beliefReport
                )
                journalField(
                    placeholder: "This feeling reminds you of…",
                    text: $echoReport
                )
                journalField(
                    placeholder: "One small thing you'll try differently next time",
                    text: $interruptionDirective
                )
            }

            // Free-flow journal, on-theme
            VStack(alignment: .leading, spacing: 6) {
                Text("Open reflection")
                    .font(.subheadline)
                    .foregroundColor(MSTheme.secondaryText)

                ZStack(alignment: .topLeading) {
                    if freeJournal.isEmpty {
                        Text("Anything else this song brought up, in your own words.")
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            .font(.caption)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $freeJournal)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                }
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
        .shadowCard()
    }

    private func journalField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                    .padding(.horizontal, 14)
            }

            TextField("", text: text)
                .foregroundColor(.white)
                .padding(10)
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - Supabase + Gemini Logic

    /// Maps a numeric intensity (1–10) to a label: "Soft", "Medium", or "Intense".
    private func intensityLabel(for value: Int) -> String {
        switch value {
        case 1...3: return "Soft"
        case 4...7: return "Medium"
        default: return "Intense"
        }
    }

    private func saveEvent() async {
        let trimmedTitle = songTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            await MainActor.run {
                HapticManager.trigger(.error)
                self.errorMessage = "Add at least a song title to save this activation."
            }
            return
        }
        do {
            let client = SupabaseClientManager.shared.client

            guard let session = try? await client.auth.session else {
                await MainActor.run {
                    HapticManager.trigger(.error)
                    self.errorMessage = "No active session."
                }
                return
            }
            
            let userId = session.user.id

            let trimmedArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
            let eventId = UUID()

            struct NewEvent: Codable {
                let id: UUID
                let user_id: UUID
                let song_title: String?
                let artist: String?
                let timestamp_sec: Int?
                let body_location: String?
                let somatic_type: String?
                let impulse: String?
                let intensity: Int?
                let intensity_label: String?
                let valence: String?
                let body_report: String?
                let impulse_report: String?
                let block_report: String?
                let echo_report: String?
                let belief_report: String?
                let pattern_report: String?
                let interruption_directive: String?
                let free_journal: String?
                let share_with_partner: Bool?
                let partner_share_level: String?
                let source_type: String?
                let source_context: String?
                let ai_reason: String?
            }

            let newEvent = NewEvent(
                id: eventId,
                user_id: session.user.id,
                song_title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                artist: trimmedArtist.isEmpty ? nil : trimmedArtist,
                timestamp_sec: timestampSeconds,
                body_location: bodyLocation.rawValue,
                somatic_type: somaticType.rawValue,
                impulse: impulse.rawValue,
                intensity: Int(intensity),
                intensity_label: intensityLabel(for: Int(intensity)),
                valence: valence.rawValue,
                body_report: bodyReport.isEmpty ? nil : bodyReport,
                impulse_report: impulseReport.isEmpty ? nil : impulseReport,
                block_report: blockReport.isEmpty ? nil : blockReport,
                echo_report: echoReport.isEmpty ? nil : echoReport,
                belief_report: beliefReport.isEmpty ? nil : beliefReport,
                pattern_report: patternReport.isEmpty ? nil : patternReport,
                interruption_directive: interruptionDirective.isEmpty ? nil : interruptionDirective,
                free_journal: freeJournal.isEmpty ? nil : freeJournal,
                share_with_partner: shareWithPartner,
                partner_share_level: "MINIMAL", // Default to MINIMAL for new events
                source_type: "manual",
                source_context: nil,
                ai_reason: nil
            )

            // DEBUG (temporary): verify user + event IDs
            print("✅ NewTriggerView.saveEvent() session.user.id = \(session.user.id)")
            print("✅ NewTriggerView.saveEvent() eventId = \(eventId)")
            print("✅ NewTriggerView.saveEvent() newEvent.user_id = \(newEvent.user_id)")

            // 1) Insert into DB (optimistic: cache will be invalidated after success)
            do {
                let _: PostgrestResponse<Void> = try await client
                    .from("song_events")
                    .insert(newEvent)
                    .execute()

                // Invalidate cache after successful insert
                DataCache.shared.invalidateEventsCache()
                DebugMode.shared.log("Invalidated events cache after creating new activation", category: "Cache")
            } catch {
                await MainActor.run {
                    HapticManager.trigger(.error)
                    self.errorMessage = "Error saving activation (DB insert): \(error.localizedDescription)"
                }
                #if DEBUG
                print("🔴 DB insert failed:", error)
                #endif
                return
            }

            // Success haptic after DB save
            await MainActor.run {
                HapticManager.trigger(.success)
            }

            // Store summary and event ID for the result screen
            await MainActor.run {
                savedEventId = eventId
                savedActivationSummary = (
                    song: trimmedTitle,
                    artist: trimmedArtist.isEmpty ? "Unknown artist" : trimmedArtist,
                    bodyLocation: bodyLocation.displayName,
                    intensityLabel: intensityLabel(for: Int(intensity))
                )
            }

            // Check for milestone celebration
            // Reload events count to check for milestone
            DataCache.shared.invalidateEventsCache()
            do {
                let allEvents: [SongEvent] = try await client
                    .from("song_events")
                    .select("id") // Just count, not full data
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if let milestone = MilestoneTracker.checkAndCelebrateMilestone(triggerCount: allEvents.count) {
                    await MainActor.run {
                        milestoneCount = milestone
                        showMilestoneCelebration = true
                        HapticManager.trigger(.heavy)
                    }
                    // Milestone overlay will show; when user dismisses it we'll show result screen
                    return
                }
            } catch {
                // Silently fail milestone check - not critical
                DebugMode.shared.log("Error checking milestone: \(error.localizedDescription)", category: "Error")
            }

            // 2) Trigger Gemini Insight (Edge Function) with song, lyrics, and timestamp so the AI can link lyrics at that time to the reflection
            do {
                try await triggerInsight(
                    eventId: eventId,
                    songTitle: trimmedTitle,
                    artist: trimmedArtist.isEmpty ? nil : trimmedArtist,
                    lyricsSnippet: lyricsSnippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : lyricsSnippet.trimmingCharacters(in: .whitespacesAndNewlines),
                    timestampSeconds: timestampSeconds
                )
            } catch {
                // Surface the function's raw body if available (we build NSError with body as localizedDescription)
                await MainActor.run {
                    HapticManager.trigger(.warning)
                    self.errorMessage = "Saved activation, but insight failed: \(error.localizedDescription)"
                }
                #if DEBUG
                print("🔴 generate_insight failed:", error)
                #endif
                // Don't return; keep UX successful since the trigger is saved.
            }

            await MainActor.run {
                self.errorMessage = nil
            }

            if showMilestoneCelebration {
                return
            }

            try? await Task.sleep(nanoseconds: 300_000_000)

            // Show result screen instead of dismissing immediately
            await MainActor.run {
                showActivationResult = true
            }

        } catch {
            let msg = error.localizedDescription
            await MainActor.run {
                HapticManager.trigger(.error)
                self.errorMessage = "Error saving: \(msg)"
            }
            #if DEBUG
            print("🔴 saveEvent() unhandled error:", error)
            #endif
        }
    }

    /// Calls the generate_insight Edge Function. Pass song, lyrics, and timestamp so the AI can fetch lyrics and link the line(s) at that time to the reflection.
    private func triggerInsight(eventId: UUID, songTitle: String, artist: String?, lyricsSnippet: String?, timestampSeconds: Int) async throws {
        let eventIdString = eventId.uuidString
        
        guard SupabaseClientManager.shared.markInsightGenerationStarted(for: eventIdString) else {
            print("⚠️ generate_insight already in-flight for event_id: \(eventIdString), skipping")
            return
        }
        
        defer {
            SupabaseClientManager.shared.markInsightGenerationCompleted(for: eventIdString)
        }
        
        let client = SupabaseClientManager.shared.client

        guard let session = try? await client.auth.session else {
            #if DEBUG
            print("🔴 No active session — cannot call generate_insight")
            #endif
            return
        }

        struct InsightPayload: Encodable {
            let event_id: UUID
            let song_title: String?
            let artist: String?
            let lyrics_snippet: String?
            /// Seconds into the song when the activation spiked; use to find lyrics at that moment.
            let timestamp_seconds: Int?
        }

        let url = SupabaseClientManager.shared.edgeFunctionURL("generate_insight")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseClientManager.shared.supabaseKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(
            InsightPayload(
                event_id: eventId,
                song_title: songTitle.isEmpty ? nil : songTitle,
                artist: artist,
                lyrics_snippet: lyricsSnippet,
                timestamp_seconds: timestampSeconds > 0 ? timestampSeconds : nil
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? "No body"
            #if DEBUG
            print("🔴 generate_insight non-200 status = \(status)")
            print("🔴 generate_insight response body = \(body)")
            #endif

            throw NSError(
                domain: "generate_insight",
                code: status,
                userInfo: [NSLocalizedDescriptionKey: body]
            )
        }

        #if DEBUG
        print("🟢 Insight successfully triggered for event \(eventId)")
        #endif
    }

    /// Poll for the insight created for the just-saved event and show it on the result screen.
    private func fetchInsightForResultScreen(eventId: UUID) async {
        let client = SupabaseClientManager.shared.client
        let maxAttempts = 30       // ~60s total (2s × 30)
        let interval: UInt64 = 2_000_000_000 // 2 seconds

        for attempt in 1...maxAttempts {
            try? await Task.sleep(nanoseconds: interval)

            let result: [ShadowInsight]? = try? await client
                .from("shadow_insights")
                .select()
                .eq("event_id", value: eventId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let insights = result, let first = insights.first {
                await MainActor.run {
                    savedActivationInsight = first
                    DataCache.shared.invalidateInsightsCache()
                }
                return
            }
        }

        await MainActor.run {
            reflectionTimedOut = true
        }
    }
}

// MARK: - Activation result (popup after save)

private struct ActivationResultView: View {
    let song: String
    let artist: String
    let bodyLocation: String
    let intensityLabel: String
    let insight: ShadowInsight?
    let reflectionTimedOut: Bool
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(MSTheme.accentGradient)

                    Text("Activation logged")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(song)
                                .font(.headline)
                                .foregroundColor(MSTheme.primaryText)
                            Spacer()
                        }
                        if !artist.isEmpty && artist != "Unknown artist" {
                            Text(artist)
                                .font(.subheadline)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        HStack(spacing: 12) {
                            Label(bodyLocation, systemImage: "figure.stand")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                            Text("·")
                                .foregroundColor(MSTheme.secondaryText.opacity(0.6))
                            Text(intensityLabel)
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )

                    // Reflection section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                            Text("Reflection")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MSTheme.secondaryText)
                        }

                        if let insight = insight {
                            reflectionContent(insight: insight)
                        } else if reflectionTimedOut {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reflection is taking longer than usual.")
                                    .font(.caption)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                                Text("Tap Done—you can see the reflection later on this trigger.")
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 16)
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(MSTheme.secondaryText)
                                Text("Generating reflection…")
                                    .font(.caption)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )

                    Button(action: onDone) {
                        HStack {
                            Text("Done")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MSTheme.accentGradient)
                        .foregroundColor(MSTheme.primaryText)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .frame(maxHeight: 520)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MSTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    @ViewBuilder
    private func reflectionContent(insight: ShadowInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let summary = insight.summary, !summary.isEmpty {
                Text(summary)
                    .font(.footnote)
                    .foregroundColor(MSTheme.primaryText.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let wound = insight.wound_type, !wound.isEmpty {
                reflectionRow(label: "Wound", value: wound)
            }
            if let protector = insight.protector_mode, !protector.isEmpty {
                reflectionRow(label: "Protector mode", value: protector)
            }
            if let belief = insight.core_belief, !belief.isEmpty {
                reflectionRow(label: "Core belief", value: belief)
            }
            if let practice = insight.suggested_practice, !practice.isEmpty {
                reflectionRow(label: "Suggested practice", value: practice)
            }
        }
    }

    private func reflectionRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText.opacity(0.85))
            Text(value)
                .font(.caption)
                .foregroundColor(MSTheme.primaryText.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
