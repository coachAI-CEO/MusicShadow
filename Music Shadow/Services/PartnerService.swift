import Combine
import Foundation
import Supabase

// MARK: - What a partner may see

/// How much of an activation a partner sees. Stored on the event as `partner_share_level`; the database
/// decides what each level returns, so this is only for display and for choosing.
enum ShareLevel: String, CaseIterable, Identifiable {
    case minimal = "MINIMAL"
    case summary = "SUMMARY"
    case full = "FULL"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minimal: return "Basics"
        case .summary: return "Summary"
        case .full:    return "Everything"
        }
    }

    var detail: String {
        switch self {
        case .minimal: return "The song, the artist, when, and how strong it was."
        case .summary: return "Adds where you felt it, the pattern you noticed, and the AI reflection."
        case .full:    return "Adds your own journal words."
        }
    }

    /// Anything unknown or missing is the most private level.
    init(stored: String?) {
        self = ShareLevel(rawValue: (stored ?? "").uppercased()) ?? .minimal
    }
}

// MARK: - Invite codes

enum PartnerCode {
    static let length = 8
    private static let alphabet = Set("ABCDEFGHJKMNPQRSTUVWXYZ23456789")

    /// What the person typed, reduced to the letters and digits a code can hold, upper case, at most 8.
    static func normalize(_ raw: String) -> String {
        String(raw.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(length))
    }

    static func isComplete(_ raw: String) -> Bool {
        let code = normalize(raw)
        return code.count == length && code.allSatisfy { alphabet.contains($0) }
    }

    /// ABCD-EFGH, easier to read and say aloud.
    static func display(_ raw: String) -> String {
        let code = normalize(raw)
        guard code.count > 4 else { return code }
        return code.prefix(4) + "-" + code.dropFirst(4)
    }

    static func shareMessage(code: String) -> String {
        "Join me on Music Shadow. Open the app, go to Settings, then Partner, and enter this code: \(display(code)). It works for 48 hours."
    }
}

// MARK: - Server shapes

struct PartnerStatus: Decodable, Equatable {
    let state: String
    let partner_name: String?
    let invite_code: String?
    let invite_expires_at: String?
    let paired_at: String?
}

struct PartnerInvite: Decodable, Equatable {
    let invite_code: String
    let invite_expires_at: String?
}

enum PartnerLinkState: Equatable {
    case none
    case invited(code: String, expiresAt: Date?)
    case paired(partnerName: String?)

    init(_ status: PartnerStatus) {
        switch status.state {
        case "paired":
            self = .paired(partnerName: status.partner_name)
        case "invited":
            if let code = status.invite_code {
                self = .invited(code: code, expiresAt: PartnerDates.parse(status.invite_expires_at))
            } else {
                self = .none
            }
        default:
            self = .none
        }
    }
}

/// One shared activation, already trimmed by the database to what its share level allows.
struct PartnerFeedItem: Decodable, Identifiable, Equatable {
    let event_id: UUID
    let created_at: String?
    let song_title: String?
    let artist: String?
    let intensity: Int?
    let valence: String?
    let share_level: String?
    let body_location: String?
    let somatic_type: String?
    let impulse: String?
    let pattern_report: String?
    let free_journal: String?
    let archetype: String?
    let wound_type: String?
    let protector_mode: String?
    let core_belief: String?
    let summary: String?

    var id: UUID { event_id }
    var level: ShareLevel { ShareLevel(stored: share_level) }
    var isPositive: Bool { (valence ?? "").lowercased() == "positive" }
    var date: Date? { PartnerDates.parse(created_at) }

    var hasReflection: Bool {
        [wound_type, protector_mode, core_belief, summary].contains { !($0 ?? "").isEmpty }
    }
}

enum PartnerDates {
    /// "2 hours ago", "yesterday".
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: now)
    }

    static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: string) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}

// MARK: - Errors

enum PartnerLinkError: Error, Equatable {
    case alreadyPaired
    case rateLimited
    case notSignedIn
    case notAvailable
    case other

    /// The database raises short codes; anything else is shown as a generic failure.
    init(_ error: Error) {
        let text = "\(error)".lowercased() + " " + error.localizedDescription.lowercased()
        if text.contains("already_paired") { self = .alreadyPaired }
        else if text.contains("rate_limited") { self = .rateLimited }
        else if text.contains("not_signed_in") { self = .notSignedIn }
        else if text.contains("could not find the function") || text.contains("pgrst202") { self = .notAvailable }
        else { self = .other }
    }

    var message: String {
        switch self {
        case .alreadyPaired: return "You're already linked with someone. Unlink first to link with a new person."
        case .rateLimited:   return "Too many tries. Please wait a little while and try again."
        case .notSignedIn:   return "Please sign in again."
        case .notAvailable:  return "Partner linking isn't available yet."
        case .other:         return "Something went wrong. Please try again."
        }
    }
}

// MARK: - API

protocol PartnerAPI {
    func status() async throws -> PartnerStatus
    func createInvite(name: String?) async throws -> PartnerInvite
    /// False when the code does not work (wrong, used, expired, or your own).
    func accept(code: String, name: String?) async throws -> Bool
    func cancelInvite() async throws
    func unlink() async throws -> Bool
    func feed(limit: Int, before: Date?) async throws -> [PartnerFeedItem]
}

struct SupabasePartnerAPI: PartnerAPI {
    private var client: SupabaseClient { SupabaseClientManager.shared.client }

    private nonisolated struct NameParams: Encodable, Sendable { let p_name: String? }
    private nonisolated struct AcceptParams: Encodable, Sendable { let p_code: String; let p_name: String? }
    private nonisolated struct FeedParams: Encodable, Sendable { let p_limit: Int; let p_before: String? }

    func status() async throws -> PartnerStatus {
        let rows: [PartnerStatus] = try await client.rpc("partner_status").execute().value
        return rows.first ?? PartnerStatus(state: "none", partner_name: nil, invite_code: nil, invite_expires_at: nil, paired_at: nil)
    }

    func createInvite(name: String?) async throws -> PartnerInvite {
        let rows: [PartnerInvite] = try await client.rpc("create_partner_invite", params: NameParams(p_name: name)).execute().value
        guard let first = rows.first else { throw PartnerLinkError.other }
        return first
    }

    func accept(code: String, name: String?) async throws -> Bool {
        let pairId: UUID? = try await client.rpc("accept_partner_invite", params: AcceptParams(p_code: code, p_name: name)).execute().value
        return pairId != nil
    }

    func cancelInvite() async throws {
        try await client.rpc("cancel_partner_invite").execute()
    }

    func unlink() async throws -> Bool {
        try await client.rpc("unlink_partner").execute().value
    }

    func feed(limit: Int, before: Date?) async throws -> [PartnerFeedItem] {
        let iso = before.map { ISO8601DateFormatter().string(from: $0) }
        return try await client.rpc("partner_feed", params: FeedParams(p_limit: limit, p_before: iso)).execute().value
    }
}

// MARK: - Link model

/// Drives the Settings screen: what the link looks like now, and the few things you can do about it.
@MainActor
final class PartnerLinkModel: ObservableObject {
    @Published private(set) var state: PartnerLinkState = .none
    @Published private(set) var isLoaded = false
    @Published private(set) var isWorking = false
    @Published var message: String?

    private let api: PartnerAPI

    init(api: PartnerAPI = SupabasePartnerAPI()) {
        self.api = api
    }

    func refresh() async {
        do {
            state = PartnerLinkState(try await api.status())
        } catch {
            message = PartnerLinkError(error).message
        }
        isLoaded = true
    }

    func createInvite(name: String) async {
        await perform {
            let invite = try await api.createInvite(name: Self.clean(name))
            state = .invited(code: invite.invite_code, expiresAt: PartnerDates.parse(invite.invite_expires_at))
        }
    }

    func join(code: String, name: String) async {
        guard PartnerCode.isComplete(code) else {
            message = "Enter the 8 characters of the code."
            return
        }
        await perform {
            let joined = try await api.accept(code: PartnerCode.normalize(code), name: Self.clean(name))
            if joined {
                state = PartnerLinkState(try await api.status())
            } else {
                message = "That code didn't work. Check it, or ask for a new one."
            }
        }
    }

    func cancelInvite() async {
        await perform {
            try await api.cancelInvite()
            state = .none
        }
    }

    func unlink() async {
        await perform {
            _ = try await api.unlink()
            state = .none
        }
    }

    private func perform(_ work: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        message = nil
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            message = PartnerLinkError(error).message
        }
    }

    private static func clean(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(40))
    }
}
