//
//  QuestData.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum QuestObjectiveType: String, Codable {
    case ascendedLevel
    case battleVictories
    case monsterKills
    case currencyCollect
}

struct QuestObjectiveDefinition: Codable, Equatable {
    let type: QuestObjectiveType
    let target: Int
    let currency: String?
}

struct QuestCharacterReward: Codable, Equatable {
    let characterID: String
}

struct QuestDefinition: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let sortOrder: Int
    let minAscendedLevel: Int?
    let objective: QuestObjectiveDefinition
    let rewards: [CurrencyAmount]
    let characterRewards: [QuestCharacterReward]
    let choiceCharacterRewardIDs: [String]

    var requiredAscendedLevel: Int {
        max(1, minAscendedLevel ?? 1)
    }
}

struct BattleFarmLimitDefinition: Codable, Equatable {
    let battleCoinsPerDay: Int
    let battleCrystalsPerDay: Int
}

struct BattleRewardLimitDefinition: Codable, Equatable {
    let coins: Int?
    let crystals: Int?

    var resolvedFarmLimits: BattleFarmLimitDefinition {
        let fallback = loadBattleFarmLimitDefinition()
        return BattleFarmLimitDefinition(
            battleCoinsPerDay: coins ?? fallback.battleCoinsPerDay,
            battleCrystalsPerDay: crystals ?? fallback.battleCrystalsPerDay
        )
    }
}

struct BattleFarmStatus: Equatable {
    let coinsEarnedToday: Int
    let crystalsEarnedToday: Int
    let coinsDailyCap: Int
    let crystalsDailyCap: Int

    var remainingCoins: Int {
        max(0, coinsDailyCap - coinsEarnedToday)
    }

    var remainingCrystals: Int {
        max(0, crystalsDailyCap - crystalsEarnedToday)
    }
}

func loadQuestDefinitions() -> [QuestDefinition] {
    JSONResourceLoader.loadArray(QuestDefinition.self, resource: "quests")
        .sorted { $0.sortOrder < $1.sortOrder }
}

func loadBattleFarmLimitDefinition() -> BattleFarmLimitDefinition {
    JSONResourceLoader.load(
        BattleFarmLimitDefinition.self,
        resource: "farm_limits"
    )
        ?? BattleFarmLimitDefinition(
            battleCoinsPerDay: 8000,
            battleCrystalsPerDay: 500
        )
}
