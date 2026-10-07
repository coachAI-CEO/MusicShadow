import SwiftUI

/// Phase 0 log: one row per completed share. The sender fills in what happened afterward.
struct SendLogView: View {
    @ObservedObject private var store = SendLogStore.shared
    private let platforms = ["Apple Music", "Spotify", "Other"]

    var body: some View {
        List {
            Section {
                let responded = store.entries.filter { $0.responded == true }.count
                Text("Sends: \(store.entries.count)   Responses: \(responded)")
                    .font(.callout.weight(.semibold))
                if !store.entries.isEmpty {
                    ShareLink(item: store.summaryText()) {
                        Label("Share this log", systemImage: "square.and.arrow.up")
                    }
                }
            }
            if store.entries.isEmpty {
                Section {
                    Text("Nothing sent yet. Open an activation and tap Send this song.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
            ForEach(store.entries) { entry in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.songTitle).font(.subheadline.weight(.semibold))
                        Text("\(entry.date.formatted(date: .abbreviated, time: .shortened)) · note \(entry.noteLength) chars · \(entry.matched ? "song link" : "search link")")
                            .font(.caption).foregroundColor(MSTheme.secondaryText)
                        Picker("They use", selection: Binding(
                            get: { entry.receiverPlatform ?? "" },
                            set: { var e = entry; e.receiverPlatform = $0.isEmpty ? nil : $0; store.update(e) }
                        )) {
                            Text("Not sure").tag("")
                            ForEach(platforms, id: \.self) { Text($0).tag($0) }
                        }
                        Toggle("They responded", isOn: Binding(
                            get: { entry.responded ?? false },
                            set: { var e = entry; e.responded = $0; store.update(e) }
                        ))
                        Toggle("It felt right to send", isOn: Binding(
                            get: { entry.feltRight ?? false },
                            set: { var e = entry; e.feltRight = $0; store.update(e) }
                        ))
                    }
                }
            }
        }
        .navigationTitle("Send log")
        .scrollContentBackground(.hidden)
        .background(MSTheme.bgGradient.ignoresSafeArea())
    }
}
