import SwiftUI

/// Central Music Shadow emblem for consistent branding.
/// 
/// NOTE: Add your emblem asset to `Assets.xcassets` with the name
/// `"MusicShadowEmblem"` to use this view. The image should be a square PNG/SVG
/// on transparent background.
struct MusicShadowEmblem: View {
    /// Rendered width/height of the emblem.
    var size: CGFloat = 40
    
    /// Optional accessibility label override.
    var accessibilityLabel: String = "Music Shadow"
    
    var body: some View {
        Image("MusicShadowEmblem")
            .resizable()
            // Treat the emblem as a single-color mark so it
            // picks up our primary text color in dark UI.
            .renderingMode(.template)
            .foregroundColor(MSTheme.primaryText)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

