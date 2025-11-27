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
}
