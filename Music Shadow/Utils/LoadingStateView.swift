import SwiftUI

/// Standardized loading/empty/error state component with retry
struct LoadingStateView<Content: View, EmptyContent: View>: View {
    let isLoading: Bool
    let isEmpty: Bool
    let errorMessage: String?
    let onRetry: (() -> Void)?
    let content: () -> Content
    let emptyContent: () -> EmptyContent
    
    init(
        isLoading: Bool,
        isEmpty: Bool,
        errorMessage: String?,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.isLoading = isLoading
        self.isEmpty = isEmpty
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.content = content
        self.emptyContent = emptyContent
    }
    
    var body: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(MSTheme.secondaryText)
                Text("Loading…")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        } else if let errorMessage = errorMessage {
            VStack(alignment: .leading, spacing: 12) {
                Text("We couldn't load this right now.")
                    .font(.headline)
                    .foregroundColor(MSTheme.primaryText)
                
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let onRetry = onRetry {
                    Button {
                        onRetry()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try again")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MSTheme.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(24)
            .shadowCard()
        } else if isEmpty {
            emptyContent()
        } else {
            content()
        }
    }
}

/// Convenience initializer for simple empty states
extension LoadingStateView where EmptyContent == EmptyStateView {
    init(
        isLoading: Bool,
        isEmpty: Bool,
        errorMessage: String?,
        emptyTitle: String,
        emptyMessage: String,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.isEmpty = isEmpty
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.content = content
        self.emptyContent = {
            EmptyStateView(title: emptyTitle, message: emptyMessage)
        }
    }
}

/// Standardized empty state view
struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(MSTheme.primaryText)
            
            Text(message)
                .font(.footnote)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .shadowCard()
    }
}
