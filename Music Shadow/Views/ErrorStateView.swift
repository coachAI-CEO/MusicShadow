// Music Shadow/Components/ErrorStateView.swift

import SwiftUI

struct ErrorStateView: View {
    let title: String
    let message: String
    let icon: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(MSTheme.Colors.error.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(MSTheme.Colors.error)
            }

            VStack(spacing: MSTheme.Spacing.sm) {
                Text(title)
                    .font(MSTheme.Typography.headline)
                    .foregroundColor(MSTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(MSTheme.Typography.body)
                    .foregroundColor(MSTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button {
                    HapticManager.trigger(.light)
                    retryAction()
                } label: {
                    HStack(spacing: MSTheme.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(MSTheme.Typography.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, MSTheme.Spacing.lg)
                    .padding(.vertical, MSTheme.Spacing.sm + 4)
                    .background(Capsule().fill(MSTheme.Colors.accentPrimary))
                }
            }
        }
        .padding(MSTheme.Spacing.xl)
    }

    static func networkError(retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Connection Error",
            message: "Please check your internet connection.",
            icon: "wifi.slash",
            retryAction: retry
        )
    }

    static func loadingError(retry: @escaping () -> Void) -> ErrorStateView {
        ErrorStateView(
            title: "Something Went Wrong",
            message: "We couldn't load your data. Please try again.",
            icon: "exclamationmark.triangle",
            retryAction: retry
        )
    }
}
