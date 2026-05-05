//
//  GlobeBattleEvent.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct GlobeNodeChestRule: Codable, Hashable {
    let minDifficulty: Int?
    let maxDifficulty: Int?
    let images: [String]

    func matches(difficulty: Int) -> Bool {
        let minimum = minDifficulty ?? .min
        let maximum = maxDifficulty ?? .max
        return minimum...maximum ~= difficulty
    }
}

struct GlobeNodeChestConfig: Codable, Hashable {
    let pointImages: [String]
    let battleRules: [GlobeNodeChestRule]
    let battleFallbackImages: [String]
    let defaultImage: String
}

private enum GlobeNodeChestConfigStore {
    private static let fallbackConfig = GlobeNodeChestConfig(
        pointImages: [
            "chest_brown",
            "chest_silver",
            "chest_gold",
            "chest_black",
            "chest_white",
        ],
        battleRules: [
            GlobeNodeChestRule(
                minDifficulty: 1,
                maxDifficulty: 4,
                images: ["chest_brown"]
            ),
            GlobeNodeChestRule(
                minDifficulty: 5,
                maxDifficulty: 7,
                images: ["chest_silver"]
            ),
            GlobeNodeChestRule(
                minDifficulty: 8,
                maxDifficulty: 10,
                images: ["chest_white"]
            ),
            GlobeNodeChestRule(
                minDifficulty: 11,
                maxDifficulty: 13,
                images: ["chest_black"]
            ),
        ],
        battleFallbackImages: [
            "chest_gold",
            "chest_black",
        ],
        defaultImage: "chest_brown"
    )

    static let shared: GlobeNodeChestConfig = {
        let config = JSONResourceLoader.loadArray(
            GlobeNodeChestConfig.self,
            resource: "globe_node_chests"
        ).first

        return config ?? fallbackConfig
    }()

    static func pointImage(for id: String) -> String {
        image(from: shared.pointImages, id: id) ?? shared.defaultImage
    }

    static func battleImage(for id: String, difficulty: Int) -> String {
        let ruleImages =
            shared.battleRules.first(where: {
                $0.matches(difficulty: difficulty)
            })?
            .images

        if let image = image(from: ruleImages ?? [], id: id) {
            return image
        }

        return image(from: shared.battleFallbackImages, id: id)
            ?? shared.defaultImage
    }

    private static func image(from images: [String], id: String) -> String? {
        let validImages = images.filter { !$0.isEmpty }
        guard !validImages.isEmpty else { return nil }
        let index = abs(id.hashValue) % validImages.count
        return validImages[index]
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
        nodeImage ?? GlobeNodeChestConfigStore.pointImage(for: id)
    }
}

struct GlobeBattle: Codable, Identifiable {
    struct CharacterReward: Codable, Identifiable, Equatable {
        let characterID: String

        var id: String { characterID }
    }

    struct CardReward: Codable, Identifiable, Equatable {
        let cardID: String
        let amount: Int

        var id: String { cardID }
    }

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
    let characterRewards: [CharacterReward]
    let cardRewards: [CardReward]
    let dailyRewardLimits: BattleRewardLimitDefinition?
    let story: [StoryLine]

    var resolvedNodeImage: String {
        nodeImage
            ?? GlobeNodeChestConfigStore.battleImage(
                for: id,
                difficulty: difficulty
            )
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
        case characterRewards
        case cardRewards
        case dailyRewardLimits
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
        characterRewards =
            try container.decodeIfPresent(
                [CharacterReward].self,
                forKey: .characterRewards
            ) ?? []
        cardRewards =
            try container.decodeIfPresent(
                [CardReward].self,
                forKey: .cardRewards
            ) ?? []
        dailyRewardLimits = try container.decodeIfPresent(
            BattleRewardLimitDefinition.self,
            forKey: .dailyRewardLimits
        )
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
