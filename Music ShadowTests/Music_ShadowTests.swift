//
//  Music_ShadowTests.swift
//  Music ShadowTests
//

import Testing
import Foundation
import UIKit
@testable import Music_Shadow

struct NoteRulesTests {
    @Test func countsScalarsNotCharacters() {
        let family = "👨‍👩‍👧‍👦"            // one Character, seven scalars (Postgres char_length = 7)
        #expect(family.count == 1)
        #expect(NoteRules.scalarCount(family) == 7)
        #expect(NoteRules.scalarCount("e\u{0301}") == 2)  // combining mark
    }

    @Test func clampStopsAtLimitOnScalarBoundary() {
        let long = String(repeating: "a", count: 600)
        #expect(NoteRules.scalarCount(NoteRules.clamp(long)) == 500)
        #expect(NoteRules.clamp("short") == "short")
    }

    @Test func clampDropsDanglingJoiner() {
        // limit lands right after a zero-width joiner
        let text = "ab\u{200D}cd"
        let clamped = NoteRules.clamp(text, to: 3)
        #expect(clamped == "ab")
    }

    @Test func emptyOrWhitespaceNoteIsNotSendable() {
        #expect(!NoteRules.isSendable(""))
        #expect(!NoteRules.isSendable("  \n  "))
        #expect(NoteRules.isSendable("I thought of you"))
        #expect(!NoteRules.isSendable(String(repeating: "a", count: 501)))
    }
}

struct StarterPromptsTests {
    @Test func hasFivePrompts() {
        #expect(StarterPrompts.all.count == 5)
    }

    @Test func insertIntoEmptyNoteDoesNotLeadWithNewline() {
        let result = StarterPrompts.insert("What do I wish you knew?", into: "")
        #expect(result == "What do I wish you knew? ")
    }

    @Test func insertAppendsOnNewLine() {
        let result = StarterPrompts.insert("What do I wish you knew?", into: "Hi")
        #expect(result == "Hi\nWhat do I wish you knew? ")
    }

    @Test func insertRespectsTheCap() {
        let full = String(repeating: "a", count: 500)
        #expect(NoteRules.scalarCount(StarterPrompts.insert("More", into: full)) <= 500)
    }
}

struct AppleMusicLinkTests {
    @Test func normalizesItunesLinkAndStripsUo() {
        let url = AppleMusicLink.normalize("https://itunes.apple.com/us/album/fade-into-you/1440848808?i=1440848810&uo=4")
        #expect(url?.host == "music.apple.com")
        #expect(url?.absoluteString == "https://music.apple.com/us/album/fade-into-you/1440848808?i=1440848810")
    }

    @Test func keepsMusicAppleLink() {
        let url = AppleMusicLink.normalize("https://music.apple.com/us/album/x/1?i=2&uo=4")
        #expect(url?.absoluteString == "https://music.apple.com/us/album/x/1?i=2")
    }

    @Test func rejectsOtherSchemesAndHosts() {
        #expect(AppleMusicLink.normalize("javascript:alert(1)") == nil)
        #expect(AppleMusicLink.normalize("http://music.apple.com/x") == nil)
        #expect(AppleMusicLink.normalize("https://music.apple.com.evil.com/x") == nil)
        #expect(AppleMusicLink.normalize("https://evil.com/music.apple.com") == nil)
        #expect(AppleMusicLink.normalize(nil) == nil)
    }

    @Test func searchURLEncodesTitleAndArtist() {
        let url = AppleMusicLink.searchURL(title: "Fade Into You", artist: "Mazzy Star")
        #expect(url?.absoluteString == "https://music.apple.com/search?term=Fade%20Into%20You%20Mazzy%20Star")
    }

    @Test func spotifySearchEncodesSpecialCharacters() {
        let url = AppleMusicLink.spotifySearchURL(title: "Don't Stop <3 & Go/Home?", artist: "Björk")
        let s = url?.absoluteString ?? ""
        #expect(s.hasPrefix("https://open.spotify.com/search/"))
        #expect(!s.dropFirst("https://open.spotify.com/search/".count).contains("/"))
        #expect(!s.contains("<"))
        #expect(!s.contains("?"))
        #expect(s.contains("Bj%C3%B6rk"))
    }
}

struct ShareMessageTests {
    @Test func putsTheNoteFirstThenSongThenLink() {
        let link = URL(string: "https://music.apple.com/us/album/x/1")
        let message = ShareMessage.build(note: "  I thought of you  ", title: "Lover", artist: "Taylor Swift", link: link)
        #expect(message == "I thought of you\n\n\"Lover\" by Taylor Swift\nhttps://music.apple.com/us/album/x/1")
    }

    @Test func worksWithoutArtistOrLink() {
        let message = ShareMessage.build(note: "Hi", title: "Lover", artist: "", link: nil)
        #expect(message == "Hi\n\n\"Lover\"")
    }
}

struct ITunesParseTests {
    @Test func parsesFirstResult() throws {
        let json = """
        {"resultCount":1,"results":[{"trackName":"Fade into You","artistName":"Mazzy Star",
        "trackViewUrl":"https://music.apple.com/us/album/fade-into-you/1440848808?i=1440848810&uo=4",
        "previewUrl":"https://audio-ssl.itunes.apple.com/x.m4a"}]}
        """.data(using: .utf8)!
        let match = ITunesSearchService.parse(json)
        #expect(match?.trackName == "Fade into You")
        #expect(match?.storeURL?.absoluteString == "https://music.apple.com/us/album/fade-into-you/1440848808?i=1440848810")
        #expect(match?.previewURL?.host == "audio-ssl.itunes.apple.com")
    }

    @Test func emptyResultsGiveNoMatch() {
        #expect(ITunesSearchService.parse(Data("{\"resultCount\":0,\"results\":[]}".utf8)) == nil)
        #expect(ITunesSearchService.parse(Data("not json".utf8)) == nil)
    }
}

struct InsightLabelsTests {
    @Test func positiveReadsAsOpenedNotWound() {
        let l = InsightLabels.labels(forValence: "positive")
        #expect(l.first == "Opened")
        #expect(l.third == "Affirms")
    }

    @Test func shadowAndMissingKeepTheOriginalLabels() {
        for v in ["shadow", nil, "", "other"] as [String?] {
            let l = InsightLabels.labels(forValence: v)
            #expect(l.first == "Wound")
            #expect(l.second == "Protector")
            #expect(l.third == "Belief")
        }
    }
}

struct FeatureFlagTests {
    @Test func partnerUIIsOffForV1() {
        #expect(FeatureFlags.partnerEnabled == false)
    }
}

struct SignatureAndDisclosureTests {
    @Test func signatureIsAppendedAfterTheNote() {
        let link = URL(string: "https://music.apple.com/us/album/x/1")
        let message = ShareMessage.build(note: "I thought of you", title: "Lover", artist: "Taylor Swift", link: link, signature: "  Leo ")
        #expect(message == "I thought of you\n\u{2014} Leo\n\n\"Lover\" by Taylor Swift\nhttps://music.apple.com/us/album/x/1")
    }

    @Test func blankSignatureAddsNothing() {
        #expect(ShareMessage.cleanSignature("   ") == nil)
        #expect(ShareMessage.cleanSignature(nil) == nil)
        let message = ShareMessage.build(note: "Hi", title: "Lover", artist: "", link: nil, signature: " ")
        #expect(message == "Hi\n\n\"Lover\"")
    }

    @Test func signatureIsOneLineAndCapped() {
        #expect(ShareMessage.cleanSignature("A\nB") == "A B")
        let long = String(repeating: "x", count: 100)
        #expect(NoteRules.scalarCount(ShareMessage.cleanSignature(long) ?? "") == 40)
    }

    @Test func disclosureSaysWhatStaysPrivateAndThatItCannotBeTakenBack() {
        #expect(ShareDisclosure.notShared.contains("AI reflection"))
        #expect(ShareDisclosure.notShared.contains("journal"))
        #expect(ShareDisclosure.when.contains("Nothing is sent yet"))
        #expect(ShareDisclosure.howLong.contains("can't turn it off"))
        #expect(ShareDisclosure.linkNote.contains("Spotify"))
    }

    @Test func linkDescriptionIsHonestAboutMatches() {
        #expect(ShareDisclosure.linkDescription(matched: true).contains("opens this song"))
        #expect(ShareDisclosure.linkDescription(matched: false).contains("couldn't find an exact match"))
    }
}

// MARK: - Light archetypes

struct LightArchetypeTests {

    private func event(_ id: UUID = UUID(), valence: String, impulse: String? = nil, somatic: String? = nil) -> SongEvent {
        var json: [String: Any] = ["id": id.uuidString, "valence": valence]
        if let impulse { json["impulse"] = impulse }
        if let somatic { json["somatic_type"] = somatic }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(SongEvent.self, from: data)
    }

    private func insight(for event: SongEvent, wound: String? = nil, protector: String? = nil, belief: String? = nil, summary: String? = nil) -> ShadowInsight {
        ShadowInsight(id: UUID(), event_id: event.id, user_id: UUID(), created_at: nil,
                      wound_type: wound, protector_mode: protector, age_range: nil, nervous_system: nil,
                      core_belief: belief, summary: summary, suggested_practice: nil)
    }

    @Test func archetypeSetsAreSplitByKind() {
        #expect(ShadowArchetype.shadowCases.count == 10)
        #expect(ShadowArchetype.lightCases.map(\.rawValue) == [
            "The Open Heart", "The Free One", "The Celebrant", "The Connector",
            "The Held One", "The Embodied One", "The Fire Keeper", "The Whole One", "The Steady One", "The Maker"
        ])
        #expect(ShadowArchetype.lightCases.allSatisfy { $0.kind == .light })
        #expect(ShadowArchetype.shadowCases.allSatisfy { $0.kind == .shadow })
    }

    @Test func everyArchetypeHasCompleteCopy() {
        for a in ShadowArchetype.allCases {
            #expect(!a.tagline.isEmpty && !a.longDescription.isEmpty && !a.coreWound.isEmpty)
            #expect(!a.nervousSystemPattern.isEmpty && !a.growthInvitation.isEmpty && !a.emoji.isEmpty)
            #expect(!a.iconName.isEmpty)
        }
    }

    @Test func everyArchetypeHasBrandArtAndLightKeepsAValidFallbackSymbol() {
        for a in ShadowArchetype.allCases {
            #expect(UIImage(named: a.iconName) != nil)
        }
        // The symbol is only shown if the brand art is ever removed, so it must still resolve.
        for a in ShadowArchetype.lightCases {
            #expect(UIImage(systemName: a.fallbackSymbol) != nil)
        }
    }

    @Test func detailCopyIsKindAware() {
        #expect(ShadowArchetype.openHeart.coreWoundTitle == "What it holds")
        #expect(ShadowArchetype.openHeart.navigationTitle == "Light archetype")
        #expect(ShadowArchetype.ghost.coreWoundTitle == "Core wound it protects")
        #expect(ShadowArchetype.ghost.navigationTitle == "Shadow archetype")
        #expect(ShadowArchetype.celebrant.growthNote != ShadowArchetype.ghost.growthNote)
        // The card title already says "What it holds"; the body must not repeat it.
        for a in ShadowArchetype.lightCases { #expect(!a.coreWound.hasPrefix("What it holds")) }
    }

    @Test func positiveReflectionsScoreLightArchetypes() {
        let e1 = event(valence: "positive")
        let e2 = event(valence: "positive")
        let e3 = event(valence: "positive")
        let e4 = event(valence: "positive")
        let insights = [
            insight(for: e1, wound: "Tenderness", summary: "The song softened something and you felt held."),
            insight(for: e2, wound: "Permission to breathe", summary: "A sense of freedom and release."),
            insight(for: e3, wound: "Joy", summary: "Pure delight, you wanted to dance."),
            insight(for: e4, wound: "Belonging", summary: "It made you think of your partner and feel connected.")
        ]
        let scores = ArchetypeEngine.lightScores(from: insights, events: [e1, e2, e3, e4])
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        #expect((byType[.openHeart] ?? 0) > 0)
        #expect((byType[.freeOne] ?? 0) > 0)
        #expect((byType[.celebrant] ?? 0) > 0)
        #expect((byType[.connector] ?? 0) > 0)
        #expect(scores.allSatisfy { $0.archetype.kind == .light })
    }

    @Test func newerLightArchetypesScoreFromPositiveReflections() {
        let events = (0..<6).map { _ in event(valence: "positive") }
        let insights = [
            insight(for: events[0], summary: "You felt cared for and soothed, as if someone would stay."),
            insight(for: events[1], summary: "Chills and a pulse you could feel, fully present in my body."),
            insight(for: events[2], summary: "A fierce song that helped you stand up and name a boundary."),
            insight(for: events[3], summary: "You felt worthy and enough as I am, with nothing to fix."),
            insight(for: events[4], summary: "Settled and grounded, safe enough to let your guard down."),
            insight(for: events[5], summary: "It sparked the urge to write and create something.")
        ]
        let scores = ArchetypeEngine.lightScores(from: insights, events: events)
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        for a in [ShadowArchetype.heldOne, .embodiedOne, .fireKeeper, .wholeOne, .steadyOne, .maker] {
            #expect((byType[a] ?? 0) > 0, "\(a.rawValue) should score")
        }
        #expect(scores.allSatisfy { $0.archetype.kind == .light })
    }

    @Test func settledBodySignalCountsForSteadyOne() {
        let settled = event(valence: "positive", somatic: "heavy")
        let scores = ArchetypeEngine.lightScores(from: [], events: [settled])
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        #expect(byType[.steadyOne] == 1)
    }

    @Test func aiPickCountsByConfidenceAndSkipsKeywordGuessing() {
        let e = event(valence: "shadow")
        var i = insight(for: e, summary: "Feels numb and disconnected, like going through the motions.")
        i.archetype = "The Ghost"; i.archetype_confidence = "high"
        let scores = ArchetypeEngine.scores(from: [i], events: [e])
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        #expect(byType[.ghost] == 3)   // the pick only; the keywords in the summary add nothing
    }

    @Test func confidenceWeightsAreThreeTwoOne() {
        func weight(_ c: String?) -> Int {
            var i = insight(for: event(valence: "shadow"))
            i.archetype = "The Mask"; i.archetype_confidence = c
            return i.pickWeight
        }
        #expect(weight("high") == 3 && weight("MEDIUM") == 2 && weight("low") == 1 && weight(nil) == 1)
    }

    @Test func insightsWithoutAPickStillScoreByKeywords() {
        let e = event(valence: "shadow")
        let i = insight(for: e, summary: "Feels numb and disconnected.")
        let scores = ArchetypeEngine.scores(from: [i], events: [e])
        #expect((scores.first { $0.archetype == .ghost }?.score ?? 0) > 0)
    }

    @Test func nonePicksAndUnknownNamesFallBackToKeywords() {
        let e = event(valence: "shadow")
        for name in ["none", "None", "The Invented One", ""] {
            var i = insight(for: e, summary: "Feels numb and disconnected.")
            i.archetype = name; i.archetype_confidence = "high"
            #expect(i.pickedArchetype == nil)
            #expect((ArchetypeEngine.scores(from: [i], events: [e]).first { $0.archetype == .ghost }?.score ?? 0) > 0)
        }
    }

    @Test func pickNamesMatchIgnoringCaseAndLeadingThe() {
        var i = insight(for: event(valence: "shadow"))
        i.archetype = "buried fire"
        #expect(i.pickedArchetype == .buriedFire)
        i.archetype = "  The Buried Fire "
        #expect(i.pickedArchetype == .buriedFire)
    }

    @Test func aLightPickOnAShadowHitIsIgnored() {
        let e = event(valence: "shadow")
        var i = insight(for: e, summary: "")
        i.archetype = "The Open Heart"; i.archetype_confidence = "high"
        let scores = ArchetypeEngine.scores(from: [i], events: [e])
        #expect(scores.allSatisfy { $0.archetype.kind == .shadow })
        #expect(scores.isEmpty)
    }

    @Test func aLightPickOnAPositiveHitCountsByConfidence() {
        let e = event(valence: "positive")
        var i = insight(for: e, summary: "")
        i.archetype = "The Maker"; i.archetype_confidence = "medium"
        let scores = ArchetypeEngine.lightScores(from: [i], events: [e])
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        #expect(byType[.maker] == 2)
    }

    @Test func lightScoringIgnoresShadowHits() {
        let shadow = event(valence: "shadow", impulse: "cling")
        let i = insight(for: shadow, summary: "Tenderness and belonging, joy and freedom.")
        #expect(ArchetypeEngine.lightScores(from: [i], events: [shadow]).isEmpty)
    }

    @Test func bodySignalsFromPositiveHitsCount() {
        let hug = event(valence: "positive", impulse: "cling")
        let tears = event(valence: "positive", somatic: "urgeCry")
        let scores = ArchetypeEngine.lightScores(from: [], events: [hug, tears])
        let byType = Dictionary(uniqueKeysWithValues: scores.map { ($0.archetype, $0.score) })
        #expect(byType[.connector] == 1)
        #expect(byType[.openHeart] == 1)
    }

    @Test func shadowScoringExcludesInsightsFromPositiveHits() {
        let positive = event(valence: "positive")
        let wound = event(valence: "shadow")
        let insights = [
            insight(for: positive, summary: "Feeling alone but then held."),   // would match abandoned child if counted
            insight(for: wound, summary: "I felt abandoned and lonely.")
        ]
        let scores = ArchetypeEngine.scores(from: insights, events: [positive, wound])
        #expect(scores.first?.archetype == .abandonedChild)
        #expect(scores.first?.score == 2)   // only the shadow hit counted
        #expect(scores.allSatisfy { $0.archetype.kind == .shadow })
    }

    @Test func shadowScoringWithoutEventsBehavesAsBefore() {
        let e = event(valence: "positive")
        let i = insight(for: e, summary: "I felt abandoned and lonely.")
        // No events passed: cannot tell the valence, so the insight counts exactly as it did before.
        let scores = ArchetypeEngine.scores(from: [i])
        #expect(scores.first?.archetype == .abandonedChild)
        #expect(scores.first?.score == 2)
    }
}

// MARK: - Capture what's playing

struct NowPlayingCaptureTests {
    private struct Fake: NowPlayingSource {
        let outcome: CaptureOutcome
        func capture() async -> CaptureOutcome { outcome }
    }

    private func song(_ title: String, source: CapturedSong.Source = .appleMusic) -> CapturedSong {
        CapturedSong(title: title, artist: "Artist", seconds: 42, source: source)
    }

    @Test func makeTrimsTextAndDropsEmptyTitles() {
        let s = CapturedSong.make(title: "  Rain \n", artist: " Sleep Token ", seconds: 127.9, source: .shazam)
        #expect(s == CapturedSong(title: "Rain", artist: "Sleep Token", seconds: 127, source: .shazam))
        #expect(CapturedSong.make(title: "   ", artist: "A", seconds: 5, source: .appleMusic) == nil)
        #expect(CapturedSong.make(title: nil, artist: "A", seconds: 5, source: .appleMusic) == nil)
    }

    @Test func makeKeepsTheArtistWhenMissingAndClampsThePosition() {
        #expect(CapturedSong.make(title: "T", artist: nil, seconds: 5, source: .appleMusic)?.artist == "")
        #expect(CapturedSong.make(title: "T", artist: "A", seconds: 99_999, source: .appleMusic)?.seconds == 1200)
        #expect(CapturedSong.make(title: "T", artist: "A", seconds: -3, source: .appleMusic)?.seconds == nil)
        #expect(CapturedSong.make(title: "T", artist: "A", seconds: .nan, source: .appleMusic)?.seconds == nil)
        #expect(CapturedSong.make(title: "T", artist: "A", seconds: nil, source: .appleMusic)?.seconds == nil)
    }

    @Test func firstSourceThatFindsASongWins() async {
        let capturer = NowPlayingCapturer(sources: [
            Fake(outcome: .song(song("First"))),
            Fake(outcome: .song(song("Second", source: .shazam)))
        ])
        #expect(await capturer.capture() == .song(song("First")))
    }

    @Test func aSourceThatFindsNothingOrIsDeniedDoesNotStopTheNext() async {
        let capturer = NowPlayingCapturer(sources: [
            Fake(outcome: .denied("Apple Music access is off.")),
            Fake(outcome: .nothing),
            Fake(outcome: .song(song("Heard it", source: .shazam)))
        ])
        #expect(await capturer.capture() == .song(song("Heard it", source: .shazam)))
    }

    @Test func aDenialIsOnlyReportedWhenNoSourceFoundASong() async {
        let denied = NowPlayingCapturer(sources: [
            Fake(outcome: .denied("Apple Music access is off.")),
            Fake(outcome: .nothing)
        ])
        #expect(await denied.capture() == .denied("Apple Music access is off."))
        let nothing = NowPlayingCapturer(sources: [Fake(outcome: .nothing), Fake(outcome: .nothing)])
        #expect(await nothing.capture() == .nothing)
        #expect(await NowPlayingCapturer(sources: []).capture() == .nothing)
    }

    @Test func theFirstDenialWins() async {
        let capturer = NowPlayingCapturer(sources: [
            Fake(outcome: .denied("one")), Fake(outcome: .denied("two"))
        ])
        #expect(await capturer.capture() == .denied("one"))
    }

    @Test func messagesExplainWhatToDo() {
        #expect(CaptureOutcome.song(song("x")).message == nil)
        #expect(CaptureOutcome.nothing.message?.contains("type the song in") == true)
        #expect(CaptureOutcome.denied("Microphone access is off.").message == "Microphone access is off.")
    }

    @Test @MainActor func aCaptureRequestIsConsumedOnce() {
        let request = CaptureRequest.shared
        request.isPending = true
        #expect(request.consume() == true)
        #expect(request.consume() == false)
    }
}
