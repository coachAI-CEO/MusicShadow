import SwiftUI

/// Animated background for onboarding that creates a gentle, musical shadow atmosphere
struct OnboardingAnimatedBackground: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.05)) { context in
            let time = context.date.timeIntervalSince1970
            
            ZStack {
                // Floating orbs - representing emotional waves/musical resonance
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.15 - Double(index) * 0.02),
                                    Color.blue.opacity(0.1 - Double(index) * 0.015),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100 + Double(index) * 30
                            )
                        )
                        .frame(width: 200 + CGFloat(index) * 50, height: 200 + CGFloat(index) * 50)
                        .offset(
                            x: sin(Double(index) * 1.2 + time * 0.5) * 80,
                            y: cos(Double(index) * 0.8 + time * 0.4) * 60
                        )
                        .blur(radius: 20)
                }
                
                // Musical wave patterns - subtle ripples
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Color.white.opacity(0.08),
                            lineWidth: 2
                        )
                        .frame(width: 150 + CGFloat(index) * 100, height: 150 + CGFloat(index) * 100)
                        .offset(
                            x: cos(Double(index) * 0.7 + time * 0.3) * 100,
                            y: sin(Double(index) * 1.1 + time * 0.4) * 80
                        )
                        .scaleEffect(1.0 + sin(time * 0.5 + Double(index)) * 0.1)
                        .opacity(0.6 - Double(index) * 0.15)
                }
                
                // Gentle pulsing center orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.2),
                                Color.blue.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)
                    .scaleEffect(1.0 + sin(time * 0.8) * 0.15)
                    .offset(x: sin(time * 0.5) * 50, y: cos(time * 0.4) * 40)
                
                // Subtle sparkles - like musical notes appearing
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .offset(
                            x: sin(Double(index) * 0.785 + time * 0.5) * 150,
                            y: cos(Double(index) * 0.785 + time * 0.4) * 120
                        )
                        .opacity(0.5 + sin(time * 0.3 + Double(index)) * 0.5)
                }
            }
        }
    }
}
