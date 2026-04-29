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

struct BattleEnergyConfigurationDefinition: Codable, Equatable {
    let maximum: Int
    let costPerBattle: Int
    let regenerationPerMinute: Int
}

struct BattleRewardPoolConfigurationDefinition: Codable, Equatable {
    let maximum: Int
    let regenerationPerMinute: Int
}

struct BattleProgressionConfigurationDefinition: Codable, Equatable {
    let energyMaximumGrowthPerAscendedLevel: Double
    let energyRegenerationGrowthPerAscendedLevel: Double
    let coinLimitMaximumGrowthPerAscendedLevel: Double
    let coinRegenerationGrowthPerAscendedLevel: Double
    let crystalLimitMaximumGrowthPerAscendedLevel: Double
    let crystalRegenerationGrowthPerAscendedLevel: Double
    let characterXPGrowthPerAscendedLevel: Double
    let characterHPGrowthPerAscendedLevel: Double
    let characterAttackGrowthPerAscendedLevel: Double
    let characterHPGrowthPerCharacterLevel: Double
    let characterAttackGrowthPerCharacterLevel: Double
}

struct BattleResourceConfigurationDefinition: Codable, Equatable {
    let energy: BattleEnergyConfigurationDefinition
    let coinLimit: BattleRewardPoolConfigurationDefinition
    let crystalLimit: BattleRewardPoolConfigurationDefinition
    let progression: BattleProgressionConfigurationDefinition
}

struct BattleEnergyResolvedConfiguration: Equatable {
    let maximum: Int
    let costPerBattle: Int
    let regenerationPerMinute: Int
}

struct BattleRewardPoolResolvedConfiguration: Equatable {
    let maximum: Int
    let regenerationPerMinute: Int
}

struct BattleResourceResolvedConfiguration: Equatable {
    let energy: BattleEnergyResolvedConfiguration
    let coinLimit: BattleRewardPoolResolvedConfiguration
    let crystalLimit: BattleRewardPoolResolvedConfiguration
    let progression: BattleProgressionConfigurationDefinition
}

struct BattleRewardLimitDefinition: Codable, Equatable {
    let coins: Int?
    let crystals: Int?

    func resolvedLimits(
        using configuration: BattleResourceResolvedConfiguration
    )
        -> BattleRewardLimitValues
    {
        BattleRewardLimitValues(
            coins: coins ?? configuration.coinLimit.maximum,
            crystals: crystals ?? configuration.crystalLimit.maximum
        )
    }
}

struct BattleRewardLimitValues: Equatable {
    let coins: Int
    let crystals: Int
}

struct BattleResourceStatus: Equatable {
    let energy: Int
    let energyMaximum: Int
    let energyCostPerBattle: Int
    let energyRegenerationPerMinute: Int
    let availableCoinsLimit: Int
    let coinsLimitMaximum: Int
    let coinsRegenerationPerMinute: Int
    let availableCrystalsLimit: Int
    let crystalsLimitMaximum: Int
    let crystalsRegenerationPerMinute: Int

    var remainingCoins: Int {
        max(0, availableCoinsLimit)
    }

    var remainingCrystals: Int {
        max(0, availableCrystalsLimit)
    }
}

extension BattleResourceConfigurationDefinition {
    func resolved(forAscendedLevel ascendedLevel: Int)
        -> BattleResourceResolvedConfiguration
    {
        let levelOffset = Double(max(0, ascendedLevel - 1))

        return BattleResourceResolvedConfiguration(
            energy: BattleEnergyResolvedConfiguration(
                maximum: scaledInt(
                    energy.maximum,
                    growth: progression.energyMaximumGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                ),
                costPerBattle: energy.costPerBattle,
                regenerationPerMinute: scaledInt(
                    energy.regenerationPerMinute,
                    growth: progression
                        .energyRegenerationGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                )
            ),
            coinLimit: BattleRewardPoolResolvedConfiguration(
                maximum: scaledInt(
                    coinLimit.maximum,
                    growth: progression.coinLimitMaximumGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                ),
                regenerationPerMinute: scaledInt(
                    coinLimit.regenerationPerMinute,
                    growth: progression.coinRegenerationGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                )
            ),
            crystalLimit: BattleRewardPoolResolvedConfiguration(
                maximum: scaledInt(
                    crystalLimit.maximum,
                    growth: progression
                        .crystalLimitMaximumGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                ),
                regenerationPerMinute: scaledInt(
                    crystalLimit.regenerationPerMinute,
                    growth: progression
                        .crystalRegenerationGrowthPerAscendedLevel,
                    levelOffset: levelOffset
                )
            ),
            progression: progression
        )
    }

    private func scaledInt(_ base: Int, growth: Double, levelOffset: Double)
        -> Int
    {
        Int((Double(base) * pow(growth, levelOffset)).rounded())
    }
}

func loadQuestDefinitions() -> [QuestDefinition] {
    JSONResourceLoader.loadArray(QuestDefinition.self, resource: "quests")
        .sorted { $0.sortOrder < $1.sortOrder }
}

func loadBattleResourceConfiguration() -> BattleResourceConfigurationDefinition
{
    JSONResourceLoader.load(
        BattleResourceConfigurationDefinition.self,
        resource: "battle_resources"
    )
        ?? BattleResourceConfigurationDefinition(
            energy: BattleEnergyConfigurationDefinition(
                maximum: 10,
                costPerBattle: 1,
                regenerationPerMinute: 1
            ),
            coinLimit: BattleRewardPoolConfigurationDefinition(
                maximum: 3000,
                regenerationPerMinute: 3000
            ),
            crystalLimit: BattleRewardPoolConfigurationDefinition(
                maximum: 300,
                regenerationPerMinute: 300
            ),
            progression: BattleProgressionConfigurationDefinition(
                energyMaximumGrowthPerAscendedLevel: 1.08,
                energyRegenerationGrowthPerAscendedLevel: 1.03,
                coinLimitMaximumGrowthPerAscendedLevel: 1.12,
                coinRegenerationGrowthPerAscendedLevel: 1.12,
                crystalLimitMaximumGrowthPerAscendedLevel: 1.10,
                crystalRegenerationGrowthPerAscendedLevel: 1.10,
                characterXPGrowthPerAscendedLevel: 1.05,
                characterHPGrowthPerAscendedLevel: 1.08,
                characterAttackGrowthPerAscendedLevel: 1.07,
                characterHPGrowthPerCharacterLevel: 1.12,
                characterAttackGrowthPerCharacterLevel: 1.10
            )
        )
}
