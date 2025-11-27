
import Foundation
import Supabase

/// Central place to hold the Supabase client + URL/key
final class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    /// Public so other files (edge function caller, etc) can reuse them
    let supabaseURL: URL
    let supabaseKey: String
    let client: SupabaseClient

    private init() {
        // 1) Project URL  (Settings → API → Project URL)
        supabaseURL = URL(string: "https://ohpgcnozjmtguffrmzgn.supabase.co")!

        // 2) API key:
        //    Use the **Publishable key** (sb_publishable_...) from:
        //    Settings → API Keys → "Publishable key"
        //    or the legacy "anon" key from the Legacy API Keys tab.
        supabaseKey = "sb_publishable_VdIVRAeFOBqnspKym8AoWw_6bY2imSo"

        // Simple, officially documented init
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }

    /// Helper to build the URL for an Edge Function
    func edgeFunctionURL(_ name: String) -> URL {
        supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent(name)
    }
}
