import SwiftUI
import Supabase

enum BodyLocation: String, CaseIterable, Identifiable {
    case chest, throat, gut, head, limbs, wholeBody, numb
    var id: String { rawValue }
}

enum SomaticType: String, CaseIterable, Identifiable {
    case tight, heavy, burning, numb, buzzing, urgeCry, urgeScream, collapse
    var id: String { rawValue }
}

enum ImpulseType: String, CaseIterable, Identifiable {
    case cry, scream, hide, cling, disappear, attack, nothing
    var id: String { rawValue }
}

// MARK: - Pretty display names

extension BodyLocation {
    var displayName: String {
        switch self {
        case .chest:      return "Chest"
        case .throat:     return "Throat"
        case .gut:        return "Gut"
        case .head:       return "Head"
        case .limbs:      return "Arms / legs"
        case .wholeBody:  return "Whole body"
        case .numb:       return "Numb / nothing"
        }
    }
}

extension SomaticType {
    var displayName: String {
        switch self {
        case .tight:        return "Tight / clenched"
        case .heavy:        return "Heavy"
        case .burning:      return "Burning"
        case .numb:         return "Numb"
        case .buzzing:      return "Buzzing / jittery"
        case .urgeCry:      return "Urge to cry"
        case .urgeScream:   return "Urge to scream"
        case .collapse:     return "Collapsed / shut down"
        }
    }
}

extension ImpulseType {
    var displayName: String {
        switch self {
        case .cry:         return "Cry"
        case .scream:      return "Scream"
        case .hide:        return "Hide / curl up"
        case .cling:       return "Cling / hold on"
        case .disappear:   return "Disappear / vanish"
        case .attack:      return "Attack / lash out"
        case .nothing:     return "Nothing / freeze"
        }
    }
}

struct NewTriggerView: View {

    // MARK: - Song
    @State private var songTitle: String = ""
    @State private var artist: String = ""
    @State private var timestampSeconds: Int = 0

    // MARK: - Somatic
    @State private var bodyLocation: BodyLocation = .chest
    @State private var somaticType: SomaticType = .tight
    @State private var impulse: ImpulseType = .cry
    @State private var intensity: Double = 5

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
    @State private var navigateToLog: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Hidden nav to Log (PatternsView)
                    NavigationLink(
                        destination: PatternsView(),
                        isActive: $navigateToLog
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Trigger")
                            .font(.title.bold())
                            .foregroundColor(MSTheme.primaryText)

                        Text("Capture how a song moved you somatically and emotionally.")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    // MARK: - SONG
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Song")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)

                        VStack(alignment: .leading, spacing: 8) {

                            // Song title
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

                    // MARK: - SOMATIC
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Somatic")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)

                        Text("Where did you feel it, how did it feel, and what did your body want to do?")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                        // BODY LOCATION
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.stand")
                                    .foregroundColor(.purple.opacity(0.9))
                                Text("Where in your body?")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                                Spacer()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(BodyLocation.allCases) { loc in
                                        SomaticChip(
                                            label: loc.displayName,
                                            isSelected: bodyLocation == loc
                                        )
                                        .onTapGesture {
                                            bodyLocation = loc
                                        }
                                    }
                                }
                            }
                        }

                        // SENSATION TYPE
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform.path")
                                    .foregroundColor(.blue.opacity(0.9))
                                Text("What did it feel like?")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                                Spacer()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(SomaticType.allCases) { t in
                                        SomaticChip(
                                            label: t.displayName,
                                            isSelected: somaticType == t
                                        )
                                        .onTapGesture {
                                            somaticType = t
                                        }
                                    }
                                }
                            }
                        }

                        // IMPULSE
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.run")
                                    .foregroundColor(.pink.opacity(0.9))
                                Text("What did your body want to do?")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                                Spacer()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ImpulseType.allCases) { i in
                                        SomaticChip(
                                            label: i.displayName,
                                            isSelected: impulse == i
                                        )
                                        .onTapGesture {
                                            impulse = i
                                        }
                                    }
                                }
                            }
                        }

                        // INTENSITY
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.yellow.opacity(0.9))
                                Text("Intensity")
                                    .font(.subheadline)
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
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                                Spacer()
                                Text("Overwhelming")
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                            }
                        }
                    }
                    .shadowCard()

                    // MARK: - JOURNAL (GUIDED + FREE)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Journal")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)

                        Text("Move through the prompts first, then let anything else spill out below.")
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
                                placeholder: "What stopped you?",
                                text: $blockReport
                            )
                            journalField(
                                placeholder: "This feeling reminds me of…",
                                text: $echoReport
                            )
                            journalField(
                                placeholder: "Belief that showed up",
                                text: $beliefReport
                            )
                            journalField(
                                placeholder: "What you usually do",
                                text: $patternReport
                            )
                            journalField(
                                placeholder: "One thing you won’t do next time",
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

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // SAVE BUTTON
                    Button {
                        Task {
                            isSaving = true
                            await saveEvent()
                            isSaving = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Save Trigger")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(24)
            }
            .musicShadowBackground()
            .navigationBarTitleDisplayMode(.inline)

            // Saving overlay
            if isSaving {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Processing your trigger…")
                        .foregroundColor(.white)
                        .font(.headline)

                    Text("Music Shadow is talking to Gemini to generate your insight.")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.65).ignoresSafeArea())
            }
        }
    }

    // MARK: - Guided field helper (single source of truth)
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
    // MARK: - SomaticChip

    struct SomaticChip: View {
        let label: String
        let isSelected: Bool

        var body: some View {
            Text(label)
                .font(.caption)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.white.opacity(0.06)
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : MSTheme.secondaryText)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                )
        }
    }
    // MARK: - Supabase + Gemini Logic
    private func saveEvent() async {
        do {
            let client = SupabaseClientManager.shared.client

            guard let session = try? await client.auth.session else {
                await MainActor.run { self.errorMessage = "No active session." }
                return
            }

            let eventId = UUID()

            struct NewEvent: Codable {
                let id: UUID
                let user_id: UUID
                let song_title: String?
                let artist: String?
                let timestamp_seconds: Int?
                let body_location: String?
                let somatic_type: String?
                let impulse: String?
                let intensity: Int?
                let body_report: String?
                let impulse_report: String?
                let block_report: String?
                let echo_report: String?
                let belief_report: String?
                let pattern_report: String?
                let interruption_directive: String?
                let free_journal: String?
            }

            let newEvent = NewEvent(
                id: eventId,
                user_id: session.user.id,
                song_title: songTitle.isEmpty ? nil : songTitle,
                artist: artist.isEmpty ? nil : artist,
                timestamp_seconds: timestampSeconds,
                body_location: bodyLocation.rawValue,
                somatic_type: somaticType.rawValue,
                impulse: impulse.rawValue,
                intensity: Int(intensity),
                body_report: bodyReport.isEmpty ? nil : bodyReport,
                impulse_report: impulseReport.isEmpty ? nil : impulseReport,
                block_report: blockReport.isEmpty ? nil : blockReport,
                echo_report: echoReport.isEmpty ? nil : echoReport,
                belief_report: beliefReport.isEmpty ? nil : beliefReport,
                pattern_report: patternReport.isEmpty ? nil : patternReport,
                interruption_directive: interruptionDirective.isEmpty ? nil : interruptionDirective,
                free_journal: freeJournal.isEmpty ? nil : freeJournal
            )

            // Insert into db
            let _: PostgrestResponse<Void> = try await client
                .from("song_events")
                .insert(newEvent)
                .execute()

            // Trigger Gemini Insight
            try await triggerInsight(eventId: eventId, sessionUserId: session.user.id)

            // On success: go straight to Log (Patterns)
            await MainActor.run {
                self.errorMessage = nil
                self.navigateToLog = true
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Error saving: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Edge Function
    private func triggerInsight(eventId: UUID, sessionUserId: UUID) async throws {
        let client = SupabaseClientManager.shared.client

        guard let session = try? await client.auth.session else {
            print("⚠️ No active session — cannot call generate_insight")
            return
        }

        struct InsightPayload: Encodable {
            let event_id: UUID
            let user_id: UUID
        }

        let url = SupabaseClientManager.shared.edgeFunctionURL("generate_insight")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseClientManager.shared.supabaseKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(
            InsightPayload(event_id: eventId, user_id: sessionUserId)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw NSError(
                domain: "generate_insight",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: body]
            )
        }

        print("✅ Insight successfully triggered!")
    }
}
