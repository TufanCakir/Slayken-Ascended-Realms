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
    let nodeImage: String?
    let cutscene: GlobeEventCutscene?
    let points: [GlobeEventPoint]

    init(
        id: String,
        title: String,
        subtitle: String,
        sortOrder: Int?,
        endsAt: String?,
        minAscendedLevel: Int?,
        mapTexture: String,
        nodeImage: String?,
        cutscene: GlobeEventCutscene?,
        points: [GlobeEventPoint]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.sortOrder = sortOrder
        self.endsAt = endsAt
        self.minAscendedLevel = minAscendedLevel
        self.mapTexture = mapTexture
        self.nodeImage = nodeImage
        self.cutscene = cutscene
        self.points = points
    }
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
    let battleGenerator: GlobeBattleGenerator?
    let battles: [GlobeBattle]

    init(
        id: String,
        title: String,
        text: String,
        mapImage: String,
        mapTexture: String,
        nodeImage: String?,
        node: EventMapNodePosition,
        cutscene: GlobeEventCutscene?,
        battleGenerator: GlobeBattleGenerator?,
        battles: [GlobeBattle]
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.mapImage = mapImage
        self.mapTexture = mapTexture
        self.nodeImage = nodeImage
        self.node = node
        self.cutscene = cutscene
        self.battleGenerator = battleGenerator
        self.battles = battles
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case text
        case mapImage
        case mapTexture
        case nodeImage
        case node
        case cutscene
        case battleGenerator
        case battles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        mapImage = try container.decode(String.self, forKey: .mapImage)
        mapTexture = try container.decode(String.self, forKey: .mapTexture)
        nodeImage = try container.decodeIfPresent(
            String.self,
            forKey: .nodeImage
        )
        node = try container.decode(EventMapNodePosition.self, forKey: .node)
        cutscene = try container.decodeIfPresent(
            GlobeEventCutscene.self,
            forKey: .cutscene
        )
        battleGenerator = try container.decodeIfPresent(
            GlobeBattleGenerator.self,
            forKey: .battleGenerator
        )

        let manualBattles =
            try container.decodeIfPresent([GlobeBattle].self, forKey: .battles)
            ?? []

        if let battleGenerator, manualBattles.isEmpty {
            battles = battleGenerator.generateBattles(
                pointID: id,
                groundTexture: mapTexture,
                skyboxTexture: mapTexture
            )
        } else {
            battles = manualBattles
        }
    }

    var resolvedNodeImage: String {
        nodeImage ?? GlobeNodeChestConfigStore.pointImage(for: id)
    }

    func resolvedNodeImage(defaultImage: String?) -> String {
        nodeImage
            ?? defaultImage
            ?? GlobeNodeChestConfigStore.pointImage(for: id)
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

struct BattleStoryDefinition: Codable, Identifiable {
    let battleID: String
    let cutscene: GlobeEventCutscene?
    let story: [StoryLine]

    var id: String { battleID }

    enum CodingKeys: String, CodingKey {
        case battleID
        case cutscene
        case story
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        battleID = try container.decode(String.self, forKey: .battleID)
        cutscene = try container.decodeIfPresent(
            GlobeEventCutscene.self,
            forKey: .cutscene
        )
        story =
            try container.decodeIfPresent([StoryLine].self, forKey: .story)
            ?? []
    }
}

struct GlobeBattleGenerator: Codable {
    let count: Int
    let enemyIDs: [String]
    let enemyGroups: [[String]]?
    let bossIDs: [String?]?
    let ids: [String]?
    let names: [String]?
    let descriptions: [String]?
    let difficulties: [Int]?
    let groundTextures: [String]?
    let skyboxTextures: [String]?
    let nodeImages: [String?]?
    let cutscenes: [GlobeEventCutscene?]?
    let groupSize: Int?
    let idPrefix: String?
    let namePrefix: String?
    let description: String?
    let startDifficulty: Int?
    let difficultyEvery: Int?
    let difficultyStep: Int?
    let groundTexture: String?
    let skyboxTexture: String?
    let nodeImage: String?
    let nodes: [EventMapNodePosition]?
    let xpReward: Int?
    let xpRewards: [Int?]?
    let rewards: [CurrencyAmount]?
    let rewardSets: [[CurrencyAmount]]?
    let characterRewards: [GlobeBattle.CharacterReward]?
    let characterRewardSets: [[GlobeBattle.CharacterReward]]?
    let skinRewards: [StorePackSkinReward]?
    let skinRewardSets: [[StorePackSkinReward]]?
    let cardRewards: [GlobeBattle.CardReward]?
    let cardRewardSets: [[GlobeBattle.CardReward]]?
    let dailyRewardLimits: BattleRewardLimitDefinition?
    let dailyRewardLimitSets: [BattleRewardLimitDefinition?]?
    let story: [StoryLine]?
    let storySets: [[StoryLine]]?

    func generateBattles(
        pointID: String,
        groundTexture defaultGroundTexture: String,
        skyboxTexture defaultSkyboxTexture: String
    ) -> [GlobeBattle] {
        guard count > 0 else { return [] }

        return (0..<count).map { index in
            let enemyGroup = enemyGroup(for: index)
            let generatedEnemies = enemyGroup.map(generatedEnemy)
            let generatedBoss = bossIDs?.element(at: index).flatMap {
                $0.map(generatedEnemy)
            }
            let battleID = "\(idPrefix ?? pointID + "_battle")_\(index + 1)"

            return GlobeBattle(
                id: ids?.element(at: index) ?? battleID,
                name: names?.element(at: index) ?? generatedName(for: index),
                description: descriptions?.element(at: index)
                    ?? description
                    ?? "",
                difficulty: difficulties?.element(at: index)
                    ?? generatedDifficulty(for: index),
                groundTexture: groundTextures?.element(at: index)
                    ?? groundTexture
                    ?? defaultGroundTexture,
                skyboxTexture: skyboxTextures?.element(at: index)
                    ?? groundTextures?.element(at: index)
                    ?? skyboxTexture
                    ?? groundTexture
                    ?? defaultSkyboxTexture,
                nodeImage: nodeImages?.element(at: index) ?? nodeImage,
                node: nodes?.element(at: index) ?? generatedNode(for: index),
                cutscene: cutscenes?.element(at: index) ?? nil,
                enemy: generatedEnemies.count == 1
                    ? generatedEnemies.first : nil,
                enemies: generatedEnemies.count > 1 ? generatedEnemies : nil,
                boss: generatedBoss,
                xpReward: xpRewards?.element(at: index) ?? xpReward,
                rewards: rewardSets?.element(at: index) ?? rewards ?? [],
                characterRewards: characterRewardSets?.element(at: index)
                    ?? characterRewards
                    ?? [],
                skinRewards: skinRewardSets?.element(at: index)
                    ?? skinRewards
                    ?? [],
                cardRewards: cardRewardSets?.element(at: index)
                    ?? cardRewards
                    ?? [],
                dailyRewardLimits: dailyRewardLimitSets?.element(at: index)
                    ?? dailyRewardLimits,
                story: storySets?.element(at: index) ?? story ?? []
            )
        }
    }

    private func enemyGroup(for index: Int) -> [String] {
        if let enemyGroups, !enemyGroups.isEmpty {
            return enemyGroups[index % enemyGroups.count].filter {
                !$0.isEmpty
            }
        }

        let validEnemyIDs = enemyIDs.filter { !$0.isEmpty }
        guard !validEnemyIDs.isEmpty else { return ["tsayi"] }

        let size = max(1, groupSize ?? 1)
        return (0..<size).map { offset in
            validEnemyIDs[(index + offset) % validEnemyIDs.count]
        }
    }

    private func generatedName(for index: Int) -> String {
        "\(namePrefix ?? "Battle") \(index + 1)"
    }

    private func generatedDifficulty(for index: Int) -> Int {
        let baseDifficulty = max(1, startDifficulty ?? 1)
        let interval = max(1, difficultyEvery ?? 1)
        let step = max(0, difficultyStep ?? 1)
        return baseDifficulty + (index / interval) * step
    }

    private func generatedNode(for index: Int) -> EventMapNodePosition {
        let column = index % 10
        let row = index / 10
        let x = min(max(0.08 + Double(column) * 0.09, 0.05), 0.94)
        let yOffset = column.isMultiple(of: 2) ? 0.0 : 0.03
        let y = min(max(0.86 - Double(row) * 0.16 - yOffset, 0.14), 0.9)
        return EventMapNodePosition(
            x: roundedNodeValue(x),
            y: roundedNodeValue(y)
        )
    }

    private func generatedEnemy(enemyID: String) -> CharacterStats {
        let payload = #"{"enemyID":"\#(enemyID)"}"#.data(using: .utf8)
        guard
            let payload,
            let enemy = try? JSONDecoder().decode(
                CharacterStats.self,
                from: payload
            )
        else {
            return CharacterStats(
                name: enemyID,
                image: "sar_dragon",
                model: enemyID,
                element: "neutral",
                hp: 100,
                attack: 10
            )
        }

        return enemy
    }

    private func roundedNodeValue(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

extension Array {
    fileprivate func element(at index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
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
    let skinRewards: [StorePackSkinReward]
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

    func resolvedNodeImage(defaultImage: String?) -> String {
        nodeImage
            ?? defaultImage
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
        case skinRewards
        case cardRewards
        case dailyRewardLimits
        case story
    }

    init(
        id: String,
        name: String,
        description: String,
        difficulty: Int,
        groundTexture: String,
        skyboxTexture: String,
        nodeImage: String? = nil,
        node: EventMapNodePosition,
        cutscene: GlobeEventCutscene? = nil,
        enemy: CharacterStats? = nil,
        enemies: [CharacterStats]? = nil,
        boss: CharacterStats? = nil,
        xpReward: Int? = nil,
        rewards: [CurrencyAmount] = [],
        characterRewards: [CharacterReward] = [],
        skinRewards: [StorePackSkinReward] = [],
        cardRewards: [CardReward] = [],
        dailyRewardLimits: BattleRewardLimitDefinition? = nil,
        story: [StoryLine] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.groundTexture = groundTexture
        self.skyboxTexture = skyboxTexture
        self.nodeImage = nodeImage
        self.node = node
        self.cutscene = cutscene
        self.enemy = enemy
        self.enemies = enemies
        self.boss = boss
        self.xpReward = xpReward
        self.rewards = rewards
        self.characterRewards = characterRewards
        self.skinRewards = skinRewards
        self.cardRewards = cardRewards
        self.dailyRewardLimits = dailyRewardLimits
        self.story = story
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
        skinRewards =
            try container.decodeIfPresent(
                [StorePackSkinReward].self,
                forKey: .skinRewards
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

private func loadBattleStoryDefinitionsByID()
    -> [String: BattleStoryDefinition]
{
    let stories = JSONResourceLoader.loadMergedIdentifiableArrays(
        BattleStoryDefinition.self,
        baseResources: [],
        autoDiscoveredWhere: {
            $0.hasPrefix("battle_story_")
                || $0.hasPrefix("event_battle_story_")
        }
    )

    return Dictionary(uniqueKeysWithValues: stories.map { ($0.battleID, $0) })
}

extension GlobeEventChapter {
    var isEventChapter: Bool {
        id.hasPrefix("event_")
    }

    func nextPointWithIncompleteBattle(
        completedBattleIDs: Set<String>
    ) -> GlobeEventPoint? {
        visiblePoints(completedBattleIDs: completedBattleIDs).first { point in
            point.battles.contains { !completedBattleIDs.contains($0.id) }
        }
    }

    func visiblePoints(completedBattleIDs: Set<String>) -> [GlobeEventPoint] {
        guard !points.isEmpty else { return [] }

        var visiblePoints: [GlobeEventPoint] = []
        for index in points.indices {
            let point = points[index]
            let isFirstPoint = index == 0
            let previousPointCompleted =
                isFirstPoint
                || points[index - 1].battles.allSatisfy {
                    completedBattleIDs.contains($0.id)
                }

            if isFirstPoint || previousPointCompleted {
                visiblePoints.append(point)
            }
        }

        return visiblePoints
    }

    func nextUnlockedPoint(
        completedBattleIDs: Set<String>
    ) -> GlobeEventPoint? {
        visiblePoints(completedBattleIDs: completedBattleIDs).first { point in
            point.visibleBattles(
                completedBattleIDs: completedBattleIDs,
                revealsSequentially: true
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

    func applyingBattleStories(
        _ storiesByBattleID: [String: BattleStoryDefinition]
    ) -> GlobeEventChapter {
        GlobeEventChapter(
            id: id,
            title: title,
            subtitle: subtitle,
            sortOrder: sortOrder,
            endsAt: endsAt,
            minAscendedLevel: minAscendedLevel,
            mapTexture: mapTexture,
            nodeImage: nodeImage,
            cutscene: cutscene,
            points: points.map {
                $0.applyingBattleStories(storiesByBattleID)
            }
        )
    }
}

extension GlobeEventPoint {
    fileprivate func applyingBattleStories(
        _ storiesByBattleID: [String: BattleStoryDefinition]
    ) -> GlobeEventPoint {
        GlobeEventPoint(
            id: id,
            title: title,
            text: text,
            mapImage: mapImage,
            mapTexture: mapTexture,
            nodeImage: nodeImage,
            node: node,
            cutscene: cutscene,
            battleGenerator: battleGenerator,
            battles: battles.map { battle in
                guard let story = storiesByBattleID[battle.id] else {
                    return battle
                }
                return battle.applyingBattleStory(story)
            }
        )
    }
}

extension GlobeBattle {
    fileprivate func applyingBattleStory(_ battleStory: BattleStoryDefinition)
        -> GlobeBattle
    {
        GlobeBattle(
            id: id,
            name: name,
            description: description,
            difficulty: difficulty,
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture,
            nodeImage: nodeImage,
            node: node,
            cutscene: battleStory.cutscene ?? cutscene,
            enemy: enemy,
            enemies: enemies,
            boss: boss,
            xpReward: xpReward,
            rewards: rewards,
            characterRewards: characterRewards,
            skinRewards: skinRewards,
            cardRewards: cardRewards,
            dailyRewardLimits: dailyRewardLimits,
            story: battleStory.story.isEmpty ? story : battleStory.story
        )
    }
}

func loadGlobeEventChapters() -> [GlobeEventChapter] {
    let baseResources = ["chapter_1", "event_story", "event_skill"]
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
    let storiesByBattleID = loadBattleStoryDefinitionsByID()

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

            chaptersByID[chapter.id] =
                chapter.applyingBattleStories(storiesByBattleID)
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
    if resourceName == "chapter_1" || resourceName == "globe_events"
        || resourceName == "event_story"
        || resourceName == "event_events"
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
    resourceName == "event_story"
        || resourceName == "event_events"
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
    case "chapter_1", "globe_events":
        return 0
    case _ where resourceName.hasPrefix("story_chapter_"),
        _ where resourceName.hasPrefix("chapter_"),
        _ where resourceName.hasPrefix("globe_chapter_"):
        return 1
    case "event_story", "event_events":
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
