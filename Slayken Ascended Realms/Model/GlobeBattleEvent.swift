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
    let sortOrder: Int?
    let endsAt: String?
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

    var mapNodeID: String {
        "point-\(id)"
    }

    func visibleBattles(
        completedBattleIDs: Set<String>,
        revealsSequentially: Bool = true
    ) -> [GlobeBattle] {
        guard revealsSequentially else { return battles }

        var result: [GlobeBattle] = []

        for index in battles.indices {
            let battle = battles[index]
            let isCompleted = completedBattleIDs.contains(battle.id)
            let previousCompleted =
                index == 0
                || completedBattleIDs.contains(battles[index - 1].id)

            if isCompleted || previousCompleted {
                result.append(battle)
            }
        }

        return result
    }

    func nextUnlockedBattle(
        completedBattleIDs: Set<String>,
        revealsSequentially: Bool = true
    ) -> GlobeBattle? {
        let battles = visibleBattles(
            completedBattleIDs: completedBattleIDs,
            revealsSequentially: revealsSequentially
        )
        return battles.first { !completedBattleIDs.contains($0.id) }
            ?? battles.last
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

    var mapNodeID: String {
        "battle-\(id)"
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

extension GlobeEventChapter {
    var isEventChapter: Bool {
        id.hasPrefix("event_")
    }

    func nextPointWithIncompleteBattle(
        completedBattleIDs: Set<String>
    ) -> GlobeEventPoint? {
        points.first { point in
            point.battles.contains { !completedBattleIDs.contains($0.id) }
        }
    }

    func nextUnlockedPoint(
        completedBattleIDs: Set<String>
    ) -> GlobeEventPoint? {
        points.first { point in
            point.visibleBattles(
                completedBattleIDs: completedBattleIDs,
                revealsSequentially: !isEventChapter
            )
            .contains { !completedBattleIDs.contains($0.id) }
        }
    }

    func isUnlocked(
        in chapters: [GlobeEventChapter],
        completedBattleIDs: Set<String>,
        ascendedLevel: Int
    ) -> Bool {
        guard ascendedLevel >= (minAscendedLevel ?? 1) else {
            return false
        }
        guard !isEventChapter else { return true }

        guard let index = chapters.firstIndex(where: { $0.id == id }) else {
            return false
        }
        guard index > 0 else { return true }

        let previousChapter = chapters[index - 1]
        let requiredBattleIDs = previousChapter.points.flatMap { point in
            point.battles.map(\.id)
        }
        return requiredBattleIDs.allSatisfy {
            completedBattleIDs.contains($0)
        }
    }
}

func loadGlobeEventChapters() -> [GlobeEventChapter] {
    let baseResources = ["globe_events", "event_events", "event_skill"]
    let autoDiscoveredResources = RemoteContentManager.cachedResourceNames()
        .filter(
            isGlobeChapterResource
        )
    let orderedResources = Array(
        Set(baseResources).union(autoDiscoveredResources)
    )
    .sorted(by: compareGlobeChapterResources)

    var chaptersByID = [String: GlobeEventChapter]()
    var resourceByChapterID = [String: String]()

    for resourceName in orderedResources {
        let chapters = JSONResourceLoader.loadArray(
            GlobeEventChapter.self,
            resource: resourceName
        )

        for chapter in chapters {
            if isEventChapterID(chapter.id)
                || isEventChapterResource(resourceName)
            {
                guard EventDateSupport.isActive(endsAt: chapter.endsAt) else {
                    continue
                }
            }

            chaptersByID[chapter.id] = chapter
            resourceByChapterID[chapter.id] = resourceName
        }
    }

    return chaptersByID.values.sorted { lhs, rhs in
        let lhsResource = resourceByChapterID[lhs.id] ?? ""
        let rhsResource = resourceByChapterID[rhs.id] ?? ""
        let lhsIsEvent =
            isEventChapterID(lhs.id) || isEventChapterResource(lhsResource)
        let rhsIsEvent =
            isEventChapterID(rhs.id) || isEventChapterResource(rhsResource)

        if lhsIsEvent != rhsIsEvent {
            return !lhsIsEvent
        }

        let lhsOrder = inferredChapterSortOrder(for: lhs, resource: lhsResource)
        let rhsOrder = inferredChapterSortOrder(for: rhs, resource: rhsResource)

        if lhsOrder != rhsOrder {
            return lhsOrder < rhsOrder
        }

        return lhs.id < rhs.id
    }
}

private func isGlobeChapterResource(_ resourceName: String) -> Bool {
    if resourceName == "globe_events" || resourceName == "event_events"
        || resourceName == "event_skill"
    {
        return true
    }

    return resourceName.hasPrefix("story_chapter_")
        || resourceName.hasPrefix("chapter_")
        || resourceName.hasPrefix("event_chapter_")
        || resourceName.hasPrefix("event_skill_")
        || resourceName.hasPrefix("globe_chapter_")
        || resourceName.hasPrefix("globe_event_")
}

private func isEventChapterResource(_ resourceName: String) -> Bool {
    resourceName == "event_events"
        || resourceName == "event_skill"
        || resourceName.hasPrefix("event_chapter_")
        || resourceName.hasPrefix("event_skill_")
        || resourceName.hasPrefix("globe_event_")
}

private func isEventChapterID(_ chapterID: String) -> Bool {
    chapterID.hasPrefix("event_")
}

private func compareGlobeChapterResources(_ lhs: String, _ rhs: String) -> Bool
{
    let lhsPriority = globeChapterResourcePriority(lhs)
    let rhsPriority = globeChapterResourcePriority(rhs)

    if lhsPriority != rhsPriority {
        return lhsPriority < rhsPriority
    }

    let lhsOrder = extractTrailingNumber(from: lhs) ?? Int.max
    let rhsOrder = extractTrailingNumber(from: rhs) ?? Int.max

    if lhsOrder != rhsOrder {
        return lhsOrder < rhsOrder
    }

    return lhs < rhs
}

private func globeChapterResourcePriority(_ resourceName: String) -> Int {
    switch resourceName {
    case "globe_events":
        return 0
    case _ where resourceName.hasPrefix("story_chapter_"),
        _ where resourceName.hasPrefix("chapter_"),
        _ where resourceName.hasPrefix("globe_chapter_"):
        return 1
    case "event_events":
        return 2
    case "event_skill":
        return 3
    case _ where resourceName.hasPrefix("event_chapter_"),
        _ where resourceName.hasPrefix("event_skill_"),
        _ where resourceName.hasPrefix("globe_event_"):
        return 4
    default:
        return 5
    }
}

private func inferredChapterSortOrder(
    for chapter: GlobeEventChapter,
    resource: String
) -> Int {
    chapter.sortOrder
        ?? extractTrailingNumber(from: chapter.id)
        ?? extractTrailingNumber(from: resource)
        ?? Int.max
}

private func extractTrailingNumber(from text: String) -> Int? {
    let digits = text.split(separator: "_").last.map(String.init) ?? text
    return Int(digits)
}
