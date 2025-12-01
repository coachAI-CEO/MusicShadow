// SomaticPractice.swift
import Foundation

struct SomaticPractice: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let durationMinutes: Int?
    let nervousSystemTargets: [String]   // e.g. ["freeze", "fawn"]
    let tags: [String]                   // e.g. ["grounding", "self-compassion"]
    let steps: [String]
}

enum SomaticToolkit {
    static let practices: [SomaticPractice] = [
        SomaticPractice(
            id: "hand-on-heart-long-exhale",
            title: "Hand on Heart + Long Exhale",
            subtitle: "For when your chest is tight and you feel alone.",
            durationMinutes: 3,
            nervousSystemTargets: ["freeze", "fawn"],
            tags: ["self-compassion", "grounding"],
            steps: [
                "Place one hand over your heart and the other on your belly. Let your shoulders drop.",
                "Inhale gently through your nose for a count of 4, feeling your chest and belly rise.",
                "Exhale slowly through your mouth for a count of 6–8, like you’re fogging a mirror.",
                "As you exhale, silently say to yourself: “It makes sense I feel this way.”",
                "Repeat this breath pattern for a few cycles, letting your chest soften even 5%."
            ]
        ),

        SomaticPractice(
            id: "wall-lean-back-body",
            title: "Wall Lean to Feel Your Back",
            subtitle: "For when you feel like you have to hold everything up alone.",
            durationMinutes: 4,
            nervousSystemTargets: ["flight", "fight"],
            tags: ["support", "grounding"],
            steps: [
                "Stand or sit with your back gently resting against a wall.",
                "Let your weight pour back into the wall by 5–10%, like it’s taking some of the load.",
                "Notice the points of contact: shoulders, spine, hips, maybe the back of your head.",
                "On each exhale, imagine the wall saying: “You don’t have to do this all by yourself.”",
                "Stay here for about a minute, just noticing where your body wants to soften."
            ]
        ),

        SomaticPractice(
            id: "orienting-5-things",
            title: "Orienting: 5 Things You See",
            subtitle: "For when everything feels too much, too fast.",
            durationMinutes: 2,
            nervousSystemTargets: ["flight", "anxiety"],
            tags: ["grounding", "present-moment"],
            steps: [
                "Let your eyes slowly scan the room or space you’re in.",
                "Name 5 things you can see, one at a time, either silently or out loud.",
                "For each one, briefly notice its color, shape, or texture.",
                "Then name 3 things you can feel physically (feet on the floor, clothes on skin, support of a chair).",
                "Let your breath be natural, and see if any small part of your body feels 1% more here."
            ]
        )
    ]

    static func practice(withId id: String) -> SomaticPractice? {
        practices.first { $0.id == id }
    }

    static var defaultPractice: SomaticPractice {
        practices.first ?? SomaticPractice(
            id: "fallback",
            title: "Hand on Heart",
            subtitle: "Simple grounding when you’re not sure where to start.",
            durationMinutes: 3,
            nervousSystemTargets: [],
            tags: [],
            steps: [
                "Place a hand on your chest.",
                "Notice your breath without changing it.",
                "Let each exhale be a tiny bit longer than the inhale."
            ]
        )
    }
}
