#if DEBUG
import SwiftUI

/// Debug-only stand-in for the server so the partner screens can be seen and tested without an account.
/// Launch with `-uiTestPartner -partnerState none|invited|paired`. Never compiled into release builds.
final class DebugPartnerAPI: PartnerAPI {
    private var state: PartnerStatus

    init(initial: String) {
        switch initial {
        case "paired":
            state = PartnerStatus(state: "paired", partner_name: "Sam", invite_code: nil, invite_expires_at: nil, paired_at: nil)
        case "invited":
            state = PartnerStatus(state: "invited", partner_name: nil, invite_code: "K7MQ4X2P",
                                  invite_expires_at: ISO8601DateFormatter().string(from: Date().addingTimeInterval(47 * 3600)), paired_at: nil)
        default:
            state = PartnerStatus(state: "none", partner_name: nil, invite_code: nil, invite_expires_at: nil, paired_at: nil)
        }
    }

    func status() async throws -> PartnerStatus { state }

    func createInvite(name: String?) async throws -> PartnerInvite {
        let expires = ISO8601DateFormatter().string(from: Date().addingTimeInterval(48 * 3600))
        state = PartnerStatus(state: "invited", partner_name: nil, invite_code: "K7MQ4X2P", invite_expires_at: expires, paired_at: nil)
        return PartnerInvite(invite_code: "K7MQ4X2P", invite_expires_at: expires)
    }

    func accept(code: String, name: String?) async throws -> Bool {
        guard code == "ABCDEFGH" else { return false }
        state = PartnerStatus(state: "paired", partner_name: "Sam", invite_code: nil, invite_expires_at: nil, paired_at: nil)
        return true
    }

    func cancelInvite() async throws {
        state = PartnerStatus(state: "none", partner_name: nil, invite_code: nil, invite_expires_at: nil, paired_at: nil)
    }

    func unlink() async throws -> Bool {
        state = PartnerStatus(state: "none", partner_name: nil, invite_code: nil, invite_expires_at: nil, paired_at: nil)
        return true
    }

    func feed(limit: Int, before: Date?) async throws -> [PartnerFeedItem] {
        func iso(_ hoursAgo: Double) -> String { ISO8601DateFormatter().string(from: Date().addingTimeInterval(-hoursAgo * 3600)) }
        let json = """
        [
         {"event_id":"10000000-0000-0000-0000-000000000003","created_at":"\(iso(2))","song_title":"Rain","artist":"Sleep Token","intensity":8,"valence":"shadow","share_level":"FULL",
          "body_location":"chest","somatic_type":"tight","impulse":"cry","pattern_report":"It happens when the song swells.","free_journal":"I did not expect it to land like that.",
          "archetype":"The Buried Fire","wound_type":"Anger turned inward","protector_mode":"Goes quiet","core_belief":"My anger is too much","summary":"Around 2:07 the line about the dust hit something old."},
         {"event_id":"10000000-0000-0000-0000-000000000002","created_at":"\(iso(30))","song_title":"Fade Into You","artist":"Mazzy Star","intensity":5,"valence":"positive","share_level":"SUMMARY",
          "body_location":"throat","somatic_type":"urgeCry","impulse":"cling","pattern_report":null,"free_journal":null,
          "archetype":"The Open Heart","wound_type":"Being held","protector_mode":"Lets itself be moved","core_belief":"It is safe to soften","summary":"A slow song that made room for tenderness."},
         {"event_id":"10000000-0000-0000-0000-000000000001","created_at":"\(iso(120))","song_title":"Atlantic","artist":"Sleep Token","intensity":4,"valence":"shadow","share_level":"MINIMAL",
          "body_location":null,"somatic_type":null,"impulse":null,"pattern_report":null,"free_journal":null,
          "archetype":null,"wound_type":null,"protector_mode":null,"core_belief":null,"summary":null}
        ]
        """.data(using: .utf8)!
        return try JSONDecoder().decode([PartnerFeedItem].self, from: json)
    }
}

struct DebugPartnerPreview: View {
    private let api: DebugPartnerAPI

    init() {
        let initial = UserDefaults.standard.string(forKey: "partnerState") ?? "none"
        api = DebugPartnerAPI(initial: initial)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PARTNER")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                    PartnerLinkView(model: PartnerLinkModel(api: api), feedAPI: api)
                        .padding(16)
                        .shadowCard()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SHARE LEVEL")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(MSTheme.secondaryText)
                        DebugShareLevel()
                    }
                    .padding(16)
                    .shadowCard()
                }
                .padding(24)
            }
            .musicShadowBackground()
            .navigationTitle("Partner preview")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

private struct DebugShareLevel: View {
    @State private var level: ShareLevel = .summary
    var body: some View { ShareLevelPicker(level: $level) }
}
#endif
