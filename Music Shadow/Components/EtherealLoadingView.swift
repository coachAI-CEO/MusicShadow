import SwiftUI

/// Ethereal loading screen with animated smoke-like elements
struct EtherealLoadingView: View {
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.3
    @State private var scale: Double = 0.8
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep charcoal background
            MSTheme.bgGradient
                .ignoresSafeArea()
            
            // Animated ethereal elements
            VStack(spacing: 40) {
                // Main animated circle (smoke-like)
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    MSTheme.accentColor.opacity(0.4),
                                    MSTheme.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                    
                    // Inner circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    MSTheme.accentColor.opacity(0.3),
                                    MSTheme.accentColor.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                        .opacity(opacity)
                    
                    // Small floating particles
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(MSTheme.accentColor.opacity(0.2))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: cos(Double(index) * .pi / 3) * 60,
                                y: sin(Double(index) * .pi / 3) * 60
                            )
                            .opacity(opacity)
                            .blur(radius: 1)
                    }
                }
                
                // App name
                VStack(spacing: 8) {
                    Text("Music Shadow")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("Reflecting on your patterns…")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            // Continuous rotation
            withAnimation(
                .linear(duration: 8)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            
            // Breathing effect
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                opacity = 0.7
                scale = 1.1
            }
            
            // Floating particles
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                offset = 10
            }
        }
    }
}

/// Full-screen loading overlay
struct EtherealLoadingOverlay: View {
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            EtherealLoadingView()
        }
    }
}

