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

struct GiftCardReward: Codable, Identifiable, Equatable {
    let cardID: String
    let amount: Int

    var id: String { cardID }
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
    let characterRewards: [GiftCharacterReward]
    let cardRewards: [GiftCardReward]

    private enum CodingKeys: String, CodingKey {
        case id
        case day
        case title
        case subtitle
        case message
        case buttonTitle
        case icon
        case rewards
        case characterRewards
        case cardRewards
    }

    init(
        id: String,
        day: Int,
        title: String,
        subtitle: String,
        message: String,
        buttonTitle: String,
        icon: String,
        rewards: [CurrencyAmount],
        characterRewards: [GiftCharacterReward] = [],
        cardRewards: [GiftCardReward] = []
    ) {
        self.id = id
        self.day = day
        self.title = title
        self.subtitle = subtitle
        self.message = message
        self.buttonTitle = buttonTitle
        self.icon = icon
        self.rewards = rewards
        self.characterRewards = characterRewards
        self.cardRewards = cardRewards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        day = try container.decode(Int.self, forKey: .day)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        message = try container.decode(String.self, forKey: .message)
        buttonTitle = try container.decode(String.self, forKey: .buttonTitle)
        icon = try container.decode(String.self, forKey: .icon)
        rewards = try container.decode([CurrencyAmount].self, forKey: .rewards)
        characterRewards =
            try container.decodeIfPresent(
                [GiftCharacterReward].self,
                forKey: .characterRewards
            ) ?? []
        cardRewards =
            try container.decodeIfPresent(
                [GiftCardReward].self,
                forKey: .cardRewards
            ) ?? []
    }
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
