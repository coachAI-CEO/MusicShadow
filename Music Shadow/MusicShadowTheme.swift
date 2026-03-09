import SwiftUI

enum MSTheme {
    static let bgGradient = LinearGradient(
        colors: [
            Color(red: 10/255, green: 10/255, blue: 25/255),
            Color(red: 30/255, green: 12/255, blue: 60/255),
            Color(red: 5/255, green: 5/255, blue: 20/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)

    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)

    enum Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
    }

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Colors {
        static let primaryText = Color.white
        static let secondaryText = Color.white.opacity(0.7)
        static let cardBackground = Color.white.opacity(0.06)
        static let cardStroke = Color.white.opacity(0.12)
        static let accentPrimary = Color(red: 180/255, green: 120/255, blue: 255/255)
        static let accentSecondary = Color(red: 140/255, green: 80/255, blue: 220/255)
        static let error = Color(red: 255/255, green: 80/255, blue: 80/255)
    }

    static let accentColor = Colors.accentPrimary
    static let accentGradient = LinearGradient(
        colors: [Colors.accentPrimary, Colors.accentSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension View {
    func musicShadowBackground() -> some View {
        ZStack {
            MSTheme.bgGradient.ignoresSafeArea()
            self
        }
    }

    func shadowCard() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MSTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
            )
    }

    func floatingActionButton() -> some View {
        self
            .font(.title2.weight(.semibold))
            .foregroundStyle(MSTheme.primaryText)
            .padding(.horizontal, MSTheme.Spacing.md)
            .padding(.vertical, MSTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                    .fill(MSTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
            )
    }

    /// Overlay a FAB that runs `action` when tapped (e.g. `.floatingActionButton { showNewTrigger = true }`).
    func floatingActionButton(action: @escaping () -> Void) -> some View {
        self.overlay(alignment: .bottomTrailing) {
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New activation")
                }
                .font(.title2.weight(.semibold))
                .foregroundStyle(MSTheme.primaryText)
                .padding(.horizontal, MSTheme.Spacing.md)
                .padding(.vertical, MSTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                        .fill(MSTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                                .stroke(MSTheme.cardStroke, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.trailing, MSTheme.Spacing.lg)
            .padding(.bottom, MSTheme.Spacing.lg)
        }
    }
}
