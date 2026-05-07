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

struct LoginRewardCampaign: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let resource: String
    let rewards: [DailyLoginRewardDefinition]
}

private struct LoginRewardCampaignManifest: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let resource: String
}

private func isLoginCampaignResource(_ resourceName: String) -> Bool {
    if resourceName == "daily_login" {
        return true
    }

    return resourceName.hasPrefix("event_login_")
        || resourceName.hasSuffix("_login")
        || resourceName.contains("_login_")
}

private func inferredLoginCampaignTitle(for resourceName: String) -> String {
    resourceName
        .split(separator: "_")
        .map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        .joined(separator: " ")
}

private func inferredLoginCampaignSubtitle(for resourceName: String) -> String {
    resourceName == "daily_login"
        ? "Remote Daily-Login-Belohnungen"
        : "Remote Event-Login-Belohnungen"
}

func loadGiftBoxDefinitions() -> [GiftBoxDefinition] {
    JSONResourceLoader.loadArray(GiftBoxDefinition.self, resource: "gift")
}

func loadDailyLoginRewardDefinitions(resource: String = "daily_login")
    -> [DailyLoginRewardDefinition]
{
    JSONResourceLoader.loadArray(
        DailyLoginRewardDefinition.self,
        resource: resource
    )
    .sorted { $0.day < $1.day }
}

func loadLoginRewardCampaigns() -> [LoginRewardCampaign] {
    let manifests = JSONResourceLoader.loadArray(
        LoginRewardCampaignManifest.self,
        resource: "login_campaigns"
    )

    let fallbackManifests = [
        LoginRewardCampaignManifest(
            id: "daily_login",
            title: "Daily Login",
            subtitle: "30 Tage Login-Belohnungen",
            resource: "daily_login"
        ),
        LoginRewardCampaignManifest(
            id: "event_login_launch",
            title: "Launch Login",
            subtitle: "Event-Login zum Release",
            resource: "event_login_launch"
        ),
        LoginRewardCampaignManifest(
            id: "event_login_festival",
            title: "Festival Login",
            subtitle: "Event-Login mit Spezialbelohnungen",
            resource: "event_login_festival"
        ),
    ]

    let configuredManifests = manifests.isEmpty ? fallbackManifests : manifests
    let configuredByResource = Dictionary(
        uniqueKeysWithValues: configuredManifests.map { ($0.resource, $0) }
    )
    let autoDiscoveredResources = RemoteContentManager.cachedResourceNames().filter(
        isLoginCampaignResource
    )

    let mergedResources = Array(
        Set(configuredByResource.keys).union(autoDiscoveredResources)
    )
    .sorted { lhs, rhs in
        if lhs == "daily_login" { return true }
        if rhs == "daily_login" { return false }
        return lhs < rhs
    }

    return mergedResources.compactMap { resourceName in
        let rewards = loadDailyLoginRewardDefinitions(resource: resourceName)
        guard !rewards.isEmpty else { return nil }

        let manifest =
            configuredByResource[resourceName]
            ?? LoginRewardCampaignManifest(
                id: resourceName,
                title: inferredLoginCampaignTitle(for: resourceName),
                subtitle: inferredLoginCampaignSubtitle(for: resourceName),
                resource: resourceName
            )

        return LoginRewardCampaign(
            id: manifest.id,
            title: manifest.title,
            subtitle: manifest.subtitle,
            resource: manifest.resource,
            rewards: rewards
        )
    }
}
