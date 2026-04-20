//
//  GlobeBattleEvent.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct GlobeEventCutscene: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let video: String?
    let text: String?
}

struct EventMapNodePosition: Codable, Equatable {
    let x: Double
    let y: Double
}

struct GlobeEventChapter: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let mapTexture: String
    let cutscene: GlobeEventCutscene?
    let points: [GlobeEventPoint]
}

struct GlobeEventPoint: Codable, Identifiable {
    let id: String
    let title: String
    let text: String
    let mapImage: String
    let mapTexture: String
    let node: EventMapNodePosition
    let cutscene: GlobeEventCutscene?
    let battles: [GlobeBattle]
}

struct GlobeBattle: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let difficulty: Int
    let groundTexture: String
    let skyboxTexture: String
    let node: EventMapNodePosition
    let cutscene: GlobeEventCutscene?
    let enemy: CharacterStats
    let enemies: [CharacterStats]?
    let boss: CharacterStats?
    let xpReward: Int?
    let rewards: [CurrencyAmount]
    let story: [StoryLine]
}

func loadGlobeEventChapters() -> [GlobeEventChapter] {
    JSONResourceLoader.loadArray(
        GlobeEventChapter.self,
        resource: "globe_events"
    )
}
