//
//  GameTutorialDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

struct GameTutorialDefinition: Codable, Identifiable {
    let id: String
    let title: String
    let objective: String
    let player: CharacterStats
    let cardRewards: [GiftCardReward]
    let enemies: [CharacterStats]
    let boss: CharacterStats?
    let retreatEnemyIndex: Int?
    let enemyRetreatThreshold: CGFloat?

    var allEnemies: [CharacterStats] {
        enemies + (boss.map { [$0] } ?? [])
    }

    var primaryEnemy: CharacterStats? {
        allEnemies.first
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case objective
        case player
        case cardRewards
        case enemy
        case enemies
        case boss
        case retreatEnemyIndex
        case enemyRetreatThreshold
    }

    init(
        id: String,
        title: String,
        objective: String,
        player: CharacterStats,
        cardRewards: [GiftCardReward],
        enemies: [CharacterStats],
        boss: CharacterStats?,
        retreatEnemyIndex: Int?,
        enemyRetreatThreshold: CGFloat?
    ) {
        self.id = id
        self.title = title
        self.objective = objective
        self.player = player
        self.cardRewards = cardRewards
        self.enemies = enemies
        self.boss = boss
        self.retreatEnemyIndex = retreatEnemyIndex
        self.enemyRetreatThreshold = enemyRetreatThreshold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        objective = try container.decode(String.self, forKey: .objective)
        player = try container.decode(CharacterStats.self, forKey: .player)
        cardRewards =
            try container.decodeIfPresent(
                [GiftCardReward].self,
                forKey: .cardRewards
            ) ?? []
        boss = try container.decodeIfPresent(CharacterStats.self, forKey: .boss)
        retreatEnemyIndex = try container.decodeIfPresent(
            Int.self,
            forKey: .retreatEnemyIndex
        )
        enemyRetreatThreshold = try container.decodeIfPresent(
            CGFloat.self,
            forKey: .enemyRetreatThreshold
        )

        if let decodedEnemies = try container.decodeIfPresent(
            [CharacterStats].self,
            forKey: .enemies
        ) {
            enemies = decodedEnemies
        } else if let singleEnemy = try container.decodeIfPresent(
            CharacterStats.self,
            forKey: .enemy
        ) {
            enemies = [singleEnemy]
        } else {
            enemies = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(objective, forKey: .objective)
        try container.encode(player, forKey: .player)
        try container.encode(cardRewards, forKey: .cardRewards)
        try container.encode(enemies, forKey: .enemies)
        try container.encodeIfPresent(boss, forKey: .boss)
        try container.encodeIfPresent(
            retreatEnemyIndex,
            forKey: .retreatEnemyIndex
        )
        try container.encodeIfPresent(
            enemyRetreatThreshold,
            forKey: .enemyRetreatThreshold
        )
    }
}

func loadTutorialDefinitions() -> [GameTutorialDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        GameTutorialDefinition.self,
        baseResources: ["tutorials"],
        autoDiscoveredWhere: {
            $0.hasPrefix("tutorials_") || $0.hasPrefix("tutorial_")
        }
    )
}
