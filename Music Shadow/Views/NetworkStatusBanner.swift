// Music Shadow/Components/NetworkStatusBanner.swift

import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var showBanner = false
    @State private var dismissed = false

    var body: some View {
        VStack {
            if showBanner && !dismissed {
                HStack(spacing: MSTheme.Spacing.sm) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .semibold))

                    Text("You're offline. Some features may be limited.")
                        .font(MSTheme.Typography.caption)

                    Spacer()

                    Button {
                        withAnimation { dismissed = true }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, MSTheme.Spacing.md)
                .padding(.vertical, MSTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md)
                        .fill(Color.orange)
                )
                .padding(.horizontal, MSTheme.Spacing.md)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showBanner)
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if !isConnected {
                dismissed = false
                showBanner = true
            } else {
                showBanner = false
            }
        }
    }
}

extension View {
    func withNetworkStatusBanner() -> some View {
        VStack(spacing: 0) {
            NetworkStatusBanner()
            self
        }
    }
}
