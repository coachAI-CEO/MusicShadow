// Music Shadow/Components/EmptyStateView.swift
import SwiftUI

struct IconEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(MSTheme.Colors.accentPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(MSTheme.Colors.accentPrimary.opacity(0.7))
            }

            VStack(spacing: MSTheme.Spacing.sm) {
                Text(title)
                    .font(MSTheme.Typography.headline)
                    .foregroundColor(MSTheme.primaryText)

                Text(message)
                    .font(MSTheme.Typography.body)
                    .foregroundColor(MSTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.trigger(.light)
                    action()
                } label: {
                    HStack(spacing: MSTheme.Spacing.sm) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(MSTheme.Typography.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, MSTheme.Spacing.lg)
                    .padding(.vertical, MSTheme.Spacing.sm + 4)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [MSTheme.Colors.accentPrimary, MSTheme.Colors.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
                }
            }
        }
        .padding(MSTheme.Spacing.xl)
    }

    static func noActivations(action: @escaping () -> Void) -> IconEmptyStateView {
        IconEmptyStateView(
            icon: "music.note",
            title: "No Activations Yet",
            message: "Start by logging your first emotional activation triggered by a song.",
            actionTitle: "Log First Activation",
            action: action
        )
    }

    static func noSearchResults(query: String) -> IconEmptyStateView {
        IconEmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No activations found matching \"\(query)\""
        )
    }
}
