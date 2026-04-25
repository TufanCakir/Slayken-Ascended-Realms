//
//  GlobeBattleEvent.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

private enum GlobeNodeChest {
    static let pointChests = [
        "chest_brown",
        "chest_silver",
        "chest_gold",
        "chest_black",
        "chest_white",
    ]

    static let battleChests = [
        "chest_brown",
        "chest_silver",
        "chest_gold",
        "chest_black",
        "chest_white",
    ]

    static func pointImage(for id: String) -> String {
        let index = abs(id.hashValue) % pointChests.count
        return pointChests[index]
    }

    static func battleImage(for id: String, difficulty: Int) -> String {
        switch difficulty {
        case 1...4:
            return "chest_brown"
        case 5...7:
            return "chest_silver"
        case 8...10:
            return "chest_white"
        case 11...13:
            return "chest_black"
        default:
            let index = abs(id.hashValue) % 2
            return index == 0 ? "chest_gold" : "chest_black"
        }
    }
}

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
    let minAscendedLevel: Int?
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
    let nodeImage: String?
    let node: EventMapNodePosition
    let cutscene: GlobeEventCutscene?
    let battles: [GlobeBattle]

    var resolvedNodeImage: String {
        nodeImage ?? GlobeNodeChest.pointImage(for: id)
    }
}

struct GlobeBattle: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let difficulty: Int
    let groundTexture: String
    let skyboxTexture: String
    let nodeImage: String?
    let node: EventMapNodePosition
    let cutscene: GlobeEventCutscene?
    let enemy: CharacterStats?
    let enemies: [CharacterStats]?
    let boss: CharacterStats?
    let xpReward: Int?
    let rewards: [CurrencyAmount]
    let story: [StoryLine]

    var resolvedNodeImage: String {
        nodeImage ?? GlobeNodeChest.battleImage(for: id, difficulty: difficulty)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case difficulty
        case groundTexture
        case skyboxTexture
        case nodeImage
        case node
        case cutscene
        case enemy
        case enemies
        case boss
        case xpReward
        case rewards
        case story
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description =
            try container.decodeIfPresent(String.self, forKey: .description)
            ?? ""
        difficulty =
            try container.decodeIfPresent(Int.self, forKey: .difficulty) ?? 1
        groundTexture =
            try container.decodeIfPresent(String.self, forKey: .groundTexture)
            ?? "map"
        skyboxTexture =
            try container.decodeIfPresent(String.self, forKey: .skyboxTexture)
            ?? groundTexture
        nodeImage = try container.decodeIfPresent(
            String.self,
            forKey: .nodeImage
        )
        node =
            try container.decodeIfPresent(
                EventMapNodePosition.self,
                forKey: .node
            )
            ?? EventMapNodePosition(x: 0.5, y: 0.5)
        cutscene = try container.decodeIfPresent(
            GlobeEventCutscene.self,
            forKey: .cutscene
        )
        enemy = try container.decodeIfPresent(
            CharacterStats.self,
            forKey: .enemy
        )
        enemies = try container.decodeIfPresent(
            [CharacterStats].self,
            forKey: .enemies
        )
        boss = try container.decodeIfPresent(CharacterStats.self, forKey: .boss)
        xpReward = try container.decodeIfPresent(Int.self, forKey: .xpReward)
        rewards =
            try container.decodeIfPresent(
                [CurrencyAmount].self,
                forKey: .rewards
            ) ?? []
        story =
            try container.decodeIfPresent([StoryLine].self, forKey: .story)
            ?? []
    }

    var battleEnemies: [CharacterStats] {
        var result: [CharacterStats] = []

        if let enemies, !enemies.isEmpty {
            result.append(contentsOf: enemies)
        } else if let enemy {
            result.append(enemy)
        }

        if let boss {
            result.append(boss)
        }

        return result.isEmpty ? [Self.defaultEnemy] : result
    }

    var primaryEnemy: CharacterStats {
        boss ?? enemies?.last ?? enemy ?? Self.defaultEnemy
    }

    private static var defaultEnemy: CharacterStats {
        CharacterStats(
            name: "Unknown Rift",
            image: "sar_dragon",
            model: "shela",
            element: "neutral",
            hp: 100,
            attack: 10
        )
    }
}

func loadGlobeEventChapters() -> [GlobeEventChapter] {
    let storyChapters = JSONResourceLoader.loadArray(
        GlobeEventChapter.self,
        resource: "globe_events"
    )
    let eventChapters = JSONResourceLoader.loadArray(
        GlobeEventChapter.self,
        resource: "event_events"
    )

    return storyChapters + eventChapters
}
