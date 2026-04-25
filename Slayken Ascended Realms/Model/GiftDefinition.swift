//
//  GiftDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct GiftCharacterReward: Codable, Identifiable, Equatable {
    let characterID: String

    var id: String { characterID }
}

struct GiftBoxDefinition: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let message: String
    let buttonTitle: String
    let icon: String
    let rewards: [CurrencyAmount]
    let characterRewards: [GiftCharacterReward]
}

struct DailyLoginRewardDefinition: Codable, Identifiable, Equatable {
    let id: String
    let day: Int
    let title: String
    let subtitle: String
    let message: String
    let buttonTitle: String
    let icon: String
    let rewards: [CurrencyAmount]
}

struct DailyLoginRewardState: Equatable {
    let reward: DailyLoginRewardDefinition
    let dayNumber: Int
}

func loadGiftBoxDefinitions() -> [GiftBoxDefinition] {
    JSONResourceLoader.loadArray(GiftBoxDefinition.self, resource: "gift")
}

func loadDailyLoginRewardDefinitions() -> [DailyLoginRewardDefinition] {
    JSONResourceLoader.loadArray(
        DailyLoginRewardDefinition.self,
        resource: "daily_login"
    )
    .sorted { $0.day < $1.day }
}
