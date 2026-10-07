import Foundation
import SwiftUI
import UIKit



// MARK: - Core Archetypes

enum ShadowArchetype: String, CaseIterable, Identifiable {
    case abandonedChild = "The Abandoned Child"
    case loneWolf       = "The Lone Wolf"
    case overachiever   = "The Overachiever"
    case invisibleOne   = "The Invisible One"
    case protector      = "The Protector"
    case mask           = "The Mask"
    case performer      = "The Performer"
    // --- New archetypes (Phase 5) ---
    case ghost          = "The Ghost"
    case buriedFire     = "The Buried Fire"
    case defectiveOne   = "The Defective One"
    // --- Light archetypes: what a positive hit points to ---
    case openHeart      = "The Open Heart"
    case freeOne        = "The Free One"
    case celebrant      = "The Celebrant"
    case connector      = "The Connector"
    case heldOne        = "The Held One"
    case embodiedOne    = "The Embodied One"
    case fireKeeper     = "The Fire Keeper"
    case wholeOne       = "The Whole One"
    case steadyOne      = "The Steady One"
    case maker          = "The Maker"

    var id: String { rawValue }

    /// Shadow archetypes describe protective patterns; light archetypes describe what lifts you.
    enum Kind { case shadow, light }

    var kind: Kind {
        switch self {
        case .openHeart, .freeOne, .celebrant, .connector,
             .heldOne, .embodiedOne, .fireKeeper, .wholeOne, .steadyOne, .maker: return .light
        default: return .shadow
        }
    }

    static var shadowCases: [ShadowArchetype] { allCases.filter { $0.kind == .shadow } }
    static var lightCases: [ShadowArchetype] { allCases.filter { $0.kind == .light } }

    /// SF Symbol used until brand art named `iconName` is added to the asset catalog.
    var fallbackSymbol: String {
        switch self {
        case .openHeart: return "heart.circle"
        case .freeOne:   return "bird"
        case .celebrant: return "sparkles"
        case .connector: return "person.2.circle"
        case .heldOne:     return "hands.sparkles"
        case .embodiedOne: return "figure.mind.and.body"
        case .fireKeeper:  return "flame"
        case .wholeOne:    return "circle.circle"
        case .steadyOne:   return "mountain.2"
        case .maker:       return "paintbrush"
        default:         return "circle"
        }
    }

    var iconName: String {
        switch self {
        case .abandonedChild: return "ArchetypeAbandonedChild"
        case .loneWolf:       return "ArchetypeLoneWolf"
        case .overachiever:   return "ArchetypeOverachiever"
        case .invisibleOne:   return "ArchetypeInvisibleOne"
        case .protector:      return "ArchetypeProtector"
        case .mask:           return "ArchetypeMask"
        case .performer:      return "ArchetypePerformer"
        case .ghost:          return "ArchetypeGhost"
        case .buriedFire:     return "ArchetypeBuriedFire"
        case .defectiveOne:   return "ArchetypeDefectiveOne"
        case .openHeart:      return "ArchetypeOpenHeart"
        case .freeOne:        return "ArchetypeFreeOne"
        case .celebrant:      return "ArchetypeCelebrant"
        case .connector:      return "ArchetypeConnector"
        case .heldOne:        return "ArchetypeHeldOne"
        case .embodiedOne:    return "ArchetypeEmbodiedOne"
        case .fireKeeper:     return "ArchetypeFireKeeper"
        case .wholeOne:       return "ArchetypeWholeOne"
        case .steadyOne:      return "ArchetypeSteadyOne"
        case .maker:          return "ArchetypeMaker"
        }
    }
    
    // Keep emoji as fallback for backwards compatibility
    var emoji: String {
        switch self {
        case .abandonedChild: return "🧸"
        case .loneWolf:       return "🐺"
        case .overachiever:   return "🏅"
        case .invisibleOne:   return "👤"
        case .protector:      return "🛡️"
        case .mask:           return "🎭"
        case .performer:      return "🎤"
        case .ghost:          return "🌫️"
        case .buriedFire:     return "🌋"
        case .defectiveOne:   return "🪞"
        case .openHeart:      return "💗"
        case .freeOne:        return "🕊️"
        case .celebrant:      return "🎉"
        case .connector:      return "🤝"
        case .heldOne:        return "🤲"
        case .embodiedOne:    return "🌊"
        case .fireKeeper:     return "🔥"
        case .wholeOne:       return "⭕️"
        case .steadyOne:      return "⛰️"
        case .maker:          return "🎨"
        }
    }

    /// Short 1-liner under the title
    var tagline: String {
        switch self {
        case .abandonedChild:
            return "Longing for care, bracing for being left."
        case .loneWolf:
            return "I’m safest when I rely on no one."
        case .overachiever:
            return "If I’m perfect, I might be enough."
        case .invisibleOne:
            return "If no one sees me, I can’t be hurt."
        case .protector:
            return "Always on guard, always managing danger."
        case .mask:
            return "I show what’s acceptable, hide what’s real."
        case .performer:
            return "I earn love by entertaining and pleasing."
        case .ghost:
            return "If I can’t feel it, I can’t be hurt by it."
        case .buriedFire:
            return "My anger was too dangerous to feel, so I swallowed it."
        case .defectiveOne:
            return "Something is fundamentally wrong with me that others can’t see yet."
        case .openHeart:
            return "I let the music soften me, and it feels safe."
        case .freeOne:
            return "This song gives me room to breathe and be myself."
        case .celebrant:
            return "I let joy move through me out loud."
        case .connector:
            return "Music is how I feel close to people."
        case .heldOne:
            return "I trust that people stay."
        case .embodiedOne:
            return "I feel it, and I’m here."
        case .fireKeeper:
            return "My anger warms. It doesn’t burn."
        case .wholeOne:
            return "I’m enough as I am."
        case .steadyOne:
            return "I’m safe enough to soften."
        case .maker:
            return "I create because it’s alive in me."
        }
    }

    /// A little more depth for the card body
    var longDescription: String {
        switch self {
        case .abandonedChild:
            return "This pattern centres around loneliness, fear of being left, and spikes when connection feels uncertain. The nervous system expects abandonment and braces for it."
        case .loneWolf:
            return "This pattern carries self-reliance and emotional distance. It’s hard to trust that others will really be there, so you carry everything alone."
        case .overachiever:
            return "This pattern ties worth to performance. Rest feels unsafe, and criticism can land like proof that you’re failing at being ‘enough’."
        case .invisibleOne:
            return "This pattern hides needs, emotions, and even presence. Blending in or disappearing has felt safer than taking up space."
        case .protector:
            return "This pattern jumps in to manage risk, anger, or chaos — often by shutting feelings down quickly to keep control."
        case .mask:
            return "This pattern curates what others see. Vulnerable parts stay behind a mask of ‘fine’, ‘together’, or ‘easygoing’."
        case .performer:
            return "This pattern reaches for charm, humour, or caretaking to stay liked and safe. Being deeply seen can feel exposing."
        case .ghost:
            return "At some point, feeling became too dangerous — so the body learned to go quiet. Music that once moved you lands flat. Aliveness feels foreign, even threatening. The disconnection isn’t weakness; it was survival."
        case .buriedFire:
            return "Anger was punished, shamed, or felt too destructive to express — so it went underground. It surfaces as depression, sharp self-criticism, or sudden explosions that feel foreign to who you think you are. The fire didn’t disappear. It turned inward."
        case .defectiveOne:
            return "Beneath the surface runs a quiet verdict: something is fundamentally wrong with me. Not something I did — something I am. This core shame pre-dates memory and shapes everything, from how compliments land to how much intimacy feels safe."
        case .openHeart:
            return "This pattern shows up when a song gets past your guard and tenderness comes through: tears, warmth, forgiveness, a softening in the chest. It is the part of you that can be moved without needing to fix or hide it."
        case .freeOne:
            return "This pattern shows up when a song loosens something you were carrying: lighter breath, more room, permission to be unguarded. It is the part of you that knows what freedom feels like in the body."
        case .celebrant:
            return "This pattern shows up when a song lights you up: energy, delight, an urge to move, sing or share the moment. It is the part of you that can enjoy being alive without apologizing for it."
        case .connector:
            return "This pattern shows up when a song makes you think of someone, or makes you feel less alone: closeness, belonging, the wish to share it. It is the part of you that reaches toward people through music."
        case .heldOne:
            return "This pattern shows up when a song feels like being cared for: comfort, steadiness, the sense that someone would stay. It is the part of you that can receive care without bracing for it to end."
        case .embodiedOne:
            return "This pattern shows up when music lands in your body and you are fully there for it: chills, warmth, a pulse you can feel. It is the part of you that can feel everything and stay present."
        case .fireKeeper:
            return "This pattern shows up when a fierce song clarifies instead of overwhelms: a boundary you can name, energy you can use, anger that feels like fuel. It is the part of you that can hold heat without being burned, or burning anyone."
        case .wholeOne:
            return "This pattern shows up when a song meets you exactly as you are and nothing needs fixing. It is the part of you that already knows your worth does not depend on performing or proving."
        case .steadyOne:
            return "This pattern shows up when a song lets your guard come down because you feel safe enough: slower breath, a settled body, nothing to manage. It is the part of you that can be strong and soft at the same time."
        case .maker:
            return "This pattern shows up when a song sparks the urge to write, build, play or make something. It is the part of you that creates because it is alive, not to prove anything."
        }
    }

    /// Underlying story this pattern is protecting
    var coreWound: String {
        switch self {
        case .abandonedChild:
            return "Fear of being left, forgotten, or too much to stay with."
        case .loneWolf:
            return "Belief that others can’t truly be trusted or depended on."
        case .overachiever:
            return "Feeling only achievements make you worthy of care or safety."
        case .invisibleOne:
            return "Sense that your needs, voice, or presence don’t really matter."
        case .protector:
            return "Expectation that things can turn unsafe quickly if you relax."
        case .mask:
            return "Fear that your real feelings or self will be rejected or shamed."
        case .performer:
            return "Belief that you must keep others happy to avoid being dropped."
        case .ghost:
            return "Early pain required complete dissociation from the body and feeling. Aliveness became synonymous with danger."
        case .buriedFire:
            return "Rage was punished or caused harm — so it was turned inward or suppressed entirely, leaving no safe place for anger to live."
        case .defectiveOne:
            return "Toxic shame — the internalized conviction of being inherently broken, unlovable, or defective at the core. Not ‘I did something bad’ but ‘I am bad.’"
        case .openHeart:
            return "A capacity for tenderness that stays open even though it has been hurt before. Worth protecting and worth noticing when it appears."
        case .freeOne:
            return "A sense of inner space and choice. It reminds you that you are not only what pressures you."
        case .celebrant:
            return "Your aliveness and appetite for joy. It is evidence that good feeling is available to you."
        case .connector:
            return "Your need for closeness and your ability to feel it. It points to who and what makes you feel at home."
        case .heldOne:
            return "Your ability to trust care when it arrives. It points to who and what makes you feel looked after."
        case .embodiedOne:
            return "Your capacity to be present in your own body. It is evidence that feeling and safety can go together."
        case .fireKeeper:
            return "Anger that has found a safe home. It carries your boundaries, your values and your energy to protect what matters."
        case .wholeOne:
            return "A quiet sense of worth that does not need earning. It is a reminder that you were enough before you did anything."
        case .steadyOne:
            return "Your ability to stay grounded and soften at the same time. It shows you what safe enough feels like."
        case .maker:
            return "Your urge to bring something new into the world. It is aliveness looking for a shape."
        }
    }

    /// Typical nervous system pattern / activation style
    var nervousSystemPattern: String {
        switch self {
        case .abandonedChild:
            return "Surges of panic or collapse when connection feels wobbly or distant."
        case .loneWolf:
            return "Numbing out, pulling away, or going hyper-independent under stress."
        case .overachiever:
            return "Driven, wired, and restless; hard time slowing down without guilt."
        case .invisibleOne:
            return "Shrink, freeze, or go blank; body wants to disappear from view."
        case .protector:
            return "Quick to tighten, brace, or go into fight / control mode."
        case .mask:
            return "Smooth on the outside while tension builds under the surface."
        case .performer:
            return "Alert to other people’s moods; body revs up to ‘fix’ the vibe."
        case .ghost:
            return "Chronic flatness, dissociation, or depersonalisation. Aliveness feels unfamiliar or threatening. Music may land without resonance — or pierce the numbness suddenly and overwhelmingly."
        case .buriedFire:
            return "Chronic low-grade depression, sudden rage that feels alien, or compulsive self-criticism — anger recycled inward because outward expression never felt safe."
        case .defectiveOne:
            return "Hypervigilance about being ‘found out’; preemptive self-attack before others can criticise; profound difficulty receiving care, love, or genuine compliments."
        case .openHeart:
            return "Softening in the chest or throat, warm tears, slower breath, a body that settles instead of bracing."
        case .freeOne:
            return "A longer exhale, loosened shoulders and jaw, lightness, a body that stops holding itself up."
        case .celebrant:
            return "Warmth and energy rising, buzzing or electric feeling, an urge to move, sing or laugh."
        case .connector:
            return "Warmth toward a person you care about, an urge to reach out or hug, a body that feels accompanied."
        case .heldOne:
            return "Slow, warm breath, a loosened chest and belly, a body that settles as if it is being held."
        case .embodiedOne:
            return "Chills, warmth or tingling you can follow, steady breath, a clear sense of where the feeling lives."
        case .fireKeeper:
            return "Heat and energy rising without panic, a firm chest, a clear jaw and hands, power that feels usable."
        case .wholeOne:
            return "A quiet, even calm: no urge to fix or hide, a body that does not brace to be judged."
        case .steadyOne:
            return "Dropped shoulders, a slower exhale, weight in the feet, a body that stops guarding."
        case .maker:
            return "Buzzing hands, a lift in the chest, restless energy that wants somewhere to go."
        }
    }

    /// Core direction for healing / growth work
    var growthInvitation: String {
        switch self {
        case .abandonedChild:
            return "Practising safe dependence: letting trusted people in and soothing the fear of being left."
        case .loneWolf:
            return "Experimenting with small, safe forms of support and co-regulation."
        case .overachiever:
            return "Letting rest, imperfection, and limits exist without making them a verdict on your worth."
        case .invisibleOne:
            return "Taking up a little more space—voice, needs, preferences—in low-risk contexts."
        case .protector:
            return "Letting the guard soften when there’s enough safety — allowing feeling instead of managing."
        case .mask:
            return "Showing tiny pieces of the real you to people who have earned your trust."
        case .performer:
            return "Letting yourself be held, not just helpful, and tolerating moments where you’re not ‘on’."
        case .ghost:
            return "Gentle re-entry into body sensation — micro-doses of pleasure, movement, and breath. Learning that the body can be a home again, not a place to escape."
        case .buriedFire:
            return "Locating the anger as information — what boundary was crossed, what mattered? — rather than as threat. Finding safe channels for the fire before it turns inward again."
        case .defectiveOne:
            return "Separating shame from guilt. Tracing the verdict to its origin. Building — slowly — a felt sense of inherent worth that doesn’t depend on performance or approval."
        case .openHeart:
            return "Notice what made it safe to soften, and make a little more room for that, with music, with people, with yourself."
        case .freeOne:
            return "Name what the song let go of, then look for one small way to give yourself that room outside the song."
        case .celebrant:
            return "Let yourself have it fully, and share it with someone if you want to. Joy you can recognize is joy you can return to."
        case .connector:
            return "Tell the person the song made you think of, in your own words. Closeness grows when it is said out loud."
        case .heldOne:
            return "Notice who or what made you feel looked after, and let a little more of that in. Care can be received in small doses."
        case .embodiedOne:
            return "Stay with the feeling for one more breath than usual. Practice noticing where in your body a good song lands."
        case .fireKeeper:
            return "Name what the song stood up for: a boundary, a value, a no. Then find one safe way to use that energy."
        case .wholeOne:
            return "Notice that nothing was asked of you. Let a moment of being enough count without proving it."
        case .steadyOne:
            return "Find what lets your guard down and give yourself more of it, on purpose, in ordinary moments."
        case .maker:
            return "Catch the spark while it’s warm: a line, a sketch, a voice note. It doesn’t need to be good, only started."
        }
    }

    // MARK: Kind-aware copy for detail screens

    var detailIntro: String {
        kind == .light
            ? "This is something that lifts you, worth knowing as well as your shadows."
            : "This is a protective pattern that developed to keep you safe."
    }
    var feelsLikeTitle: String { kind == .light ? "How this tends to feel" : "How this pattern tends to feel" }
    var coreWoundTitle: String { kind == .light ? "What it holds" : "Core wound it protects" }
    var nervousSystemTitle: String { kind == .light ? "In the body" : "Nervous system pattern" }
    var growthTitle: String { kind == .light ? "How to keep it close" : "Growth invitation" }
    var growthNote: String {
        kind == .light
            ? "Small, ordinary moments are enough. You can come back to this any time."
            : "You don't have to change everything at once. Small experiments count."
    }
    var detailClosing: String {
        kind == .light
            ? "You don't have to earn this. It was already part of you."
            : "This pattern isn't a problem — it's a protector that learned early."
    }
    var navigationTitle: String { kind == .light ? "Light archetype" : "Shadow archetype" }
}

// MARK: - Score wrapper

struct ArchetypeScore: Identifiable {
    let id = UUID()
    let archetype: ShadowArchetype
    let score: Int
}

// MARK: - Scoring Engine

struct ArchetypeEngine {

    /// Single canonical scoring used by both ContentView (hero card) and PatternsView (Archetypes tab).
    static func scores(from insights: [ShadowInsight], events: [SongEvent] = []) -> [ArchetypeScore] {
        var buckets: [ShadowArchetype: Int] = [:]
        func bump(_ type: ShadowArchetype, by amount: Int = 1) {
            buckets[type, default: 0] += amount
        }

        // Insights from positive hits describe what lifted you, not a wound, so they do not feed
        // the shadow archetypes. With no event list we cannot tell, so every insight counts (as before).
        let positiveEventIds = Set(events.filter { $0.isPositive }.map { $0.id })

        // 1) AI insights (same logic as PatternsView for consistency)
        for insight in insights where !positiveEventIds.contains(insight.event_id) {
            let blob = [
                insight.wound_type,
                insight.protector_mode,
                insight.core_belief,
                insight.summary
            ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

            // Abandoned Child
            if blob.containsAny(of: ["abandon", "left", "alone", "lonely", "rejected", "unwanted"]) {
                bump(.abandonedChild, by: 2)
            }
            if blob.containsAny(of: ["unworthy of love", "not lovable", "too much", "not enough"]) {
                bump(.abandonedChild, by: 1)
            }

            // Lone Wolf
            if blob.containsAny(of: ["can only rely on myself", "others are unsafe", "don’t need anyone", "better alone"]) {
                bump(.loneWolf, by: 2)
            }
            if blob.containsAny(of: ["distance", "shut down", "withdraw", "pull away"]) {
                bump(.loneWolf, by: 1)
            }

            // Overachiever
            if blob.containsAny(of: ["perform", "achieve", "perfect", "high standards", "failure is not allowed"]) {
                bump(.overachiever, by: 2)
            }
            if blob.containsAny(of: ["if i don’t", "need to prove", "never enough"]) {
                bump(.overachiever, by: 1)
            }

            // Invisible One
            if blob.containsAny(of: ["invisible", "not seen", "ignored", "overlooked", "fade into the background"]) {
                bump(.invisibleOne, by: 2)
            }
            if blob.containsAny(of: ["don’t take up space", "don’t want to bother", "stay quiet"]) {
                bump(.invisibleOne, by: 1)
            }

            // Protector
            if blob.containsAny(of: ["protector", "protect", "guard", "keep control", "shut it down"]) {
                bump(.protector, by: 2)
            }
            if blob.containsAny(of: ["fight", "freeze", "contain feelings"]) {
                bump(.protector, by: 1)
            }

            // Mask
            if blob.containsAny(of: ["hide feelings", "hide myself", "put on a face", "mask", "pretend"]) {
                bump(.mask, by: 2)
            }
            if blob.containsAny(of: ["people pleasing", "don’t show weakness", "keep it together"]) {
                bump(.mask, by: 1)
            }

            // Performer
            if blob.containsAny(of: ["performer", "entertainer", "make others laugh", "keep everyone happy"]) {
                bump(.performer, by: 2)
            }
            if blob.containsAny(of: ["fix the mood", "take care of everyone", "be the strong one"]) {
                bump(.performer, by: 1)
            }

            // Ghost
            if blob.containsAny(of: ["numb", "disconnected", "dissociat", "nothing lands", "can't feel", "frozen inside", "detached", "blank", "empty inside", "going through the motions"]) {
                bump(.ghost, by: 2)
            }
            if blob.containsAny(of: ["flat", "shut down", "switched off", "no feeling", "hollow", "not present", "checked out"]) {
                bump(.ghost, by: 1)
            }

            // Buried Fire
            if blob.containsAny(of: ["rage", "anger is dangerous", "can't be angry", "swallowed my anger", "buried anger", "suppressed rage", "anger turned inward", "fury"]) {
                bump(.buriedFire, by: 2)
            }
            if blob.containsAny(of: ["boiling", "explosion", "self-blame", "depression as anger", "no right to be angry", "punished for anger", "too much anger"]) {
                bump(.buriedFire, by: 1)
            }

            // Defective One
            if blob.containsAny(of: ["something wrong with me", "fundamentally broken", "unlovable", "defective", "if they knew the real me", "toxic shame", "inherently bad", "shameful at core"]) {
                bump(.defectiveOne, by: 2)
            }
            if blob.containsAny(of: ["shame", "not enough", "too much", "found out", "fraud", "worthless", "wrong with me", "damaged"]) {
                bump(.defectiveOne, by: 1)
            }
        }

        // 2) Raw impulses / sensations from events (same as PatternsView)
        let impulses = events.compactMap { $0.impulse?.lowercased() }
        let sensations = events.compactMap { $0.somatic_type?.lowercased() }
        let impulseCounts = Dictionary(grouping: impulses, by: { $0 }).mapValues { $0.count }
        let sensationCounts = Dictionary(grouping: sensations, by: { $0 }).mapValues { $0.count }
        if (impulseCounts["cry"] ?? 0) > 0 || (sensationCounts["tight"] ?? 0) > 0 { bump(.abandonedChild) }
        if (impulseCounts["disappear"] ?? 0) > 0 || (impulseCounts["hide"] ?? 0) > 0 { bump(.invisibleOne) }
        if (impulseCounts["attack"] ?? 0) > 0 { bump(.protector) }
        if (impulseCounts["cling"] ?? 0) > 0 { bump(.abandonedChild) }
        return buckets
            .map { ArchetypeScore(archetype: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }

    /// Light archetypes, scored only from positive hits: the AI reflection text plus how the body responded.
    static func lightScores(from insights: [ShadowInsight], events: [SongEvent]) -> [ArchetypeScore] {
        var buckets: [ShadowArchetype: Int] = [:]
        func bump(_ type: ShadowArchetype, by amount: Int = 1) {
            buckets[type, default: 0] += amount
        }

        let positiveEvents = events.filter { $0.isPositive }
        let positiveIds = Set(positiveEvents.map { $0.id })

        for insight in insights where positiveIds.contains(insight.event_id) {
            let blob = [insight.wound_type, insight.protector_mode, insight.core_belief, insight.summary]
                .compactMap { $0?.lowercased() }
                .joined(separator: " ")

            // Open Heart
            if blob.containsAny(of: ["tender", "soften", "vulnerab", "compassion", "forgive", "melt", "moved to tears", "open-hearted", "opened"]) {
                bump(.openHeart, by: 2)
            }
            if blob.containsAny(of: ["gentle", "safe to feel", "held", "warm", "love", "soft"]) {
                bump(.openHeart, by: 1)
            }

            // Free One
            if blob.containsAny(of: ["freedom", "liberat", "unburden", "let go", "release", "unbound", "room to breathe", "space to breathe"]) {
                bump(.freeOne, by: 2)
            }
            if blob.containsAny(of: ["free", "lightness", "permission", "own pace", "unguarded", "breathe"]) {
                bump(.freeOne, by: 1)
            }

            // Celebrant
            if blob.containsAny(of: ["joy", "celebrat", "delight", "elated", "triumph", "dance", "playful", "gratitude", "grateful"]) {
                bump(.celebrant, by: 2)
            }
            if blob.containsAny(of: ["alive", "energy", "excite", "party", "sing", "laugh"]) {
                bump(.celebrant, by: 1)
            }

            // Connector
            if blob.containsAny(of: ["belong", "togetherness", "closeness", "connection", "connected", "understood", "share it", "wants to share", "someone"]) {
                bump(.connector, by: 2)
            }
            if blob.containsAny(of: ["together", "seen", "home", "partner", "community", "accompanied", "reach out"]) {
                bump(.connector, by: 1)
            }

            // Held One
            if blob.containsAny(of: ["cared for", "looked after", "secure", "soothed", "comforted", "reassur", "nurtur", "unconditional"]) {
                bump(.heldOne, by: 2)
            }
            if blob.containsAny(of: ["protected", "accepted", "feel known", "trust", "someone would stay"]) {
                bump(.heldOne, by: 1)
            }

            // Embodied One
            if blob.containsAny(of: ["in my body", "embod", "goosebump", "chills", "fully present", "felt it all", "feel it all", "pulse", "tingl"]) {
                bump(.embodiedOne, by: 2)
            }
            if blob.containsAny(of: ["resonan", "sensation"]) {
                bump(.embodiedOne, by: 1)
            }

            // Fire Keeper
            if blob.containsAny(of: ["boundary", "boundaries", "empower", "righteous", "stand up", "standing up", "fierce", "assertive", "say no", "cathartic", "fuel"]) {
                bump(.fireKeeper, by: 2)
            }
            if blob.containsAny(of: ["power", "courage", "clarity", "strength"]) {
                bump(.fireKeeper, by: 1)
            }

            // Whole One
            if blob.containsAny(of: ["enough as i am", "self-acceptance", "worthy", "nothing to fix", "wholeness", "complete", "deserv", "at peace with myself", "as i am"]) {
                bump(.wholeOne, by: 2)
            }
            if blob.containsAny(of: ["worth", "peace", "content", "self-compassion", "whole"]) {
                bump(.wholeOne, by: 1)
            }

            // Steady One
            if blob.containsAny(of: ["steady", "grounded", "anchor", "stable", "settled", "safe enough", "guard down", "unclench", "secure footing"]) {
                bump(.steadyOne, by: 2)
            }
            if blob.containsAny(of: ["calm", "relax", "centered", "balance", "stillness"]) {
                bump(.steadyOne, by: 1)
            }

            // Maker
            if blob.containsAny(of: ["creat", "inspir", "make something", "songwrit", "compose", "imagin", "spark", "urge to write", "artistic"]) {
                bump(.maker, by: 2)
            }
            if blob.containsAny(of: ["write", "build", "express", "craft", "vision", "idea"]) {
                bump(.maker, by: 1)
            }
        }

        // Body signals from positive hits (the form relabels these options for positive hits)
        for event in positiveEvents {
            switch (event.impulse ?? "").lowercased() {
            case "cry":       bump(.openHeart)     // "Tear up / soften"
            case "cling":     bump(.connector)     // "Reach out / hug"
            case "scream":    bump(.celebrant)     // "Sing / shout"
            case "attack":    bump(.celebrant)     // "Move / take action"
            case "disappear": bump(.freeOne)       // "Drift / float"
            default: break
            }
            switch (event.somatic_type ?? "").lowercased() {
            case "urgecry":    bump(.openHeart)    // "Moved to tears"
            case "collapse":   bump(.freeOne)      // "Melted / relaxed"
            case "heavy":      bump(.freeOne); bump(.steadyOne)   // "Grounded / settled"
            case "burning", "buzzing", "urgescream", "tight": bump(.celebrant)  // warm, excited, burst, charged
            default: break
            }
        }

        return buckets
            .map { ArchetypeScore(archetype: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }
}

// MARK: - String helper

private extension String {
    func containsAny(of needles: [String]) -> Bool {
        let lower = self.lowercased()
        return needles.contains(where: { lower.contains($0) })
    }
}

// MARK: - UI Card

struct ShadowArchetypeCard: View {
    let primary: ArchetypeScore?
    let secondary: ArchetypeScore?
    var title: String = "Shadow archetype"
    var blurb: String = "Music Shadow’s best guess at the pattern your triggers are orbiting around. It will update as you log more."
    var emptyText: String = "Log a few triggers with reflections to unlock your archetype."
    var secondaryLabel: String = "Secondary pattern:"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text(blurb)
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            if let primary {
                HStack(spacing: 12) {
                    ArchetypeIcon(archetype: primary.archetype, size: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(primary.archetype.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        Text(primary.archetype.tagline)
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(primary.archetype.longDescription)
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } else {
                Text(emptyText)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .padding(.top, 4)
            }

            if let secondary {
                Divider()
                    .background(MSTheme.cardStroke)

                HStack(spacing: 6) {
                    Text(secondaryLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text(secondary.archetype.rawValue)
                        .font(.caption)
                        .foregroundColor(MSTheme.primaryText)

                    Spacer()
                }
            }
        }
        .shadowCard()
    }
}


// MARK: - Icon (brand art when present, SF Symbol otherwise)

/// Uses the brand image named by `iconName` when it exists in the asset catalog. The light archetypes
/// have no brand art yet, so they fall back to an SF Symbol; adding art with the matching name replaces it.
struct ArchetypeIcon: View {
    let archetype: ShadowArchetype
    var size: CGFloat = 40
    var color: Color = MSTheme.primaryText

    var body: some View {
        Group {
            if UIImage(named: archetype.iconName) != nil {
                Image(archetype.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
            } else {
                Image(systemName: archetype.fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            }
        }
        .foregroundColor(color)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
