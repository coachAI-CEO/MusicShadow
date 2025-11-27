import SwiftUI

struct AllTriggersView: View {
    let events: [SongEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your logged triggers")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("Scroll through everything you’ve logged so far.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.bottom, 4)

                if events.isEmpty {
                    Text("No triggers logged yet.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 10) {
                        ForEach(events) { event in
                            NavigationLink(
                                destination: TriggerDetailView(event: event)
                            ) {
                                TriggerRow(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Triggers")
        .navigationBarTitleDisplayMode(.inline)
    }
}//
//  Untitled.swift
//  Music Shadow
//
//  Created by macbook on 11/26/25.
//

