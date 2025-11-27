import SwiftUI

struct WhyItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: – Hero
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why Music Shadow works")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("A simple way to track how music lights up your nervous system, memories, and beliefs.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                        .lineSpacing(2)
                }
                .padding(.top, 12)

                // MARK: – 1. Music → Body → Story flow
                VStack(alignment: .leading, spacing: 16) {
                    Text("From song to shadow")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("When a song hits, your body reacts before your mind explains it. Music Shadow captures that full chain.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                    HStack(spacing: 8) {
                        flowStep(
                            icon: "music.note",
                            title: "Music",
                            subtitle: "A lyric, riff, or melody lands harder than expected."
                        )

                        Image(systemName: "chevron.right")
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))

                        flowStep(
                            icon: "waveform.path.ecg",
                            title: "Body spike",
                            subtitle: "Chest tightens, stomach drops, throat closes, urge to run or cry."
                        )

                        Image(systemName: "chevron.right")
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))

                        flowStep(
                            icon: "brain.head.profile",
                            title: "Shadow story",
                            subtitle: "Old memories and beliefs wake up underneath the moment."
                        )
                    }
                }
                .shadowCard()

                // MARK: – 2. Nervous system science
                VStack(alignment: .leading, spacing: 12) {
                    Text("The science in the background")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    scienceRow(
                        icon: "bolt.heart",
                        title: "Music bypasses the thinking brain",
                        text: "Sound hits emotional + memory circuits (amygdala, hippocampus) before your logical mind catches up. That’s why songs can drop you straight into a feeling."
                    )

                    scienceRow(
                        icon: "figure.walk.motion",
                        title: "Your body holds the receipts",
                        text: "Tightness, buzzing, collapse, or urges to run are nervous-system responses shaped by past experiences. They show you where the shadow lives."
                    )

                    scienceRow(
                        icon: "square.grid.3x3.fill",
                        title: "Patterns = implicit memory",
                        text: "When similar spikes repeat across different songs and days, you’re seeing a deeper pattern—an old map your system keeps following."
                    )
                }
                .shadowCard()

                // MARK: – 3. How logging rewires the pattern
                VStack(alignment: .leading, spacing: 12) {
                    Text("How logging changes things")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("You’re not just journaling—you’re slowly teaching your system a new response.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                    VStack(alignment: .leading, spacing: 8) {
                        numberedStep(
                            number: "1",
                            title: "Notice the spike",
                            text: "You catch the moment your body flares instead of going fully on autopilot."
                        )
                        numberedStep(
                            number: "2",
                            title: "Name body + impulse",
                            text: "You map where it lands and what your body wants to do. This turns raw activation into information."
                        )
                        numberedStep(
                            number: "3",
                            title: "See the pattern",
                            text: "Over time, Music Shadow shows you recurring body hotspots, impulses, and beliefs."
                        )
                        numberedStep(
                            number: "4",
                            title: "Practice something new",
                            text: "With small somatic practices, you give your nervous system a different script to try next time."
                        )
                    }
                }
                .shadowCard()

                // MARK: – 4. What the AI is actually doing
                VStack(alignment: .leading, spacing: 12) {
                    Text("What the AI is doing (and not doing)")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 46, height: 46)

                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .semibold))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("A gentle mirror, not a judge")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MSTheme.primaryText)

                            Text("The model reads your somatic data and journal entries, then offers a best-guess snapshot: possible wound themes, protector modes, and a simple practice.")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("It doesn’t diagnose you or know “the truth” about you. It’s a reflection you can keep, tweak, or ignore—your lived experience stays in charge.")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .shadowCard()

                // MARK: – 5. Where this is going
                VStack(alignment: .leading, spacing: 10) {
                    Text("Where this can go over time")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("As you keep logging, Music Shadow can help you:")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                    VStack(alignment: .leading, spacing: 6) {
                        bullet("See which artists and songs light up specific wounds or memories.")
                        bullet("Track how your intensity shifts as you do therapy, breathwork, or other practices.")
                        bullet("Bring a clear, visual map of your triggers into sessions with your therapist or coach.")
                    }
                }
                .shadowCard()

                // Spacer at bottom
                Text("This is not a replacement for therapy or crisis support. It’s a companion for noticing, naming, and softening what music reveals.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    .padding(.bottom, 24)
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Why it works")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Small building blocks

    private func flowStep(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
            }

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scienceRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.purple.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                Text(text)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func numberedStep(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                Text(text)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText)
            Text(text)
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
