import SwiftUI

/// Music Shadow emblem — uses the real image asset from Assets.xcassets.
/// The image should be named "MusicShadowEmblem" and have a transparent background.
struct MusicShadowEmblem: View {
    var size: CGFloat = 40
    var color: Color = .white

    var body: some View {
        Image("MusicShadowEmblem")
            .resizable()
            .renderingMode(.template)   // lets us tint it any color
            .foregroundColor(color)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color(red: 10/255, green: 10/255, blue: 25/255)
        VStack(spacing: 24) {
            MusicShadowEmblem(size: 80)
            MusicShadowEmblem(size: 40)
            MusicShadowEmblem(size: 24)
        }
    }
    .ignoresSafeArea()
}
