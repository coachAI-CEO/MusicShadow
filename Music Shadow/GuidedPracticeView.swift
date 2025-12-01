// GuidedPracticeView.swift
import SwiftUI

struct GuidedPracticeView: View {
    let practice: SomaticPractice
    @State private var stepIndex: Int = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(practice.title)
                    .font(.title2.bold())
                    .foregroundColor(MSTheme.primaryText)

                if let subtitle = practice.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }

                if let minutes = practice.durationMinutes {
                    Text("Approx. \(minutes) min")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }

                if !practice.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(practice.tags.prefix(3), id: \.self) { tag in
                            Text(tag.uppercased())
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            // Progress
            HStack(spacing: 6) {
                ForEach(practice.steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIndex ? Color.purple : Color.white.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.top, 4)

            // Current step
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(stepIndex + 1) of \(practice.steps.count)")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)

                Text(practice.steps[stepIndex])
                    .font(.body)
                    .foregroundColor(MSTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(18)

            Spacer()

            // Controls
            HStack(spacing: 12) {
                Button {
                    if stepIndex > 0 {
                        stepIndex -= 1
                    }
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .disabled(stepIndex == 0)
                .background(
                    Color.white.opacity(stepIndex == 0 ? 0.06 : 0.12)
                )
                .cornerRadius(14)
                .foregroundColor(MSTheme.primaryText.opacity(stepIndex == 0 ? 0.4 : 1))

                Button {
                    if stepIndex < practice.steps.count - 1 {
                        stepIndex += 1
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(stepIndex == practice.steps.count - 1 ? "Finish" : "Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .foregroundColor(.white)
            }
        }
        .padding(24)
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}
