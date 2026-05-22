//
//  AbilityCardDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum AbilityCardTargeting: String, Codable, Equatable {
    case single
    case allEnemies
}

struct AbilityCardDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let image: String
    let element: String
    let rarity: Int?
    let damageMultiplier: Double
    let particleEffect: String
    let description: String
    let manaCost: Int?
    let maxLevel: Int?
    let maxStars: Int?
    let duplicatesPerLevel: Int?
    let levelsPerStar: Int?
    let damageGrowth: Double?
    let targeting: AbilityCardTargeting?
    let source: String?
    let isLimited: Bool?
    let limitedUntil: String?

    var resolvedRarity: Int { rarity ?? resolvedMaxStars }
    var resolvedManaCost: Int { manaCost ?? 35 }
    var resolvedMaxLevel: Int { maxLevel ?? 30 }
    var resolvedMaxStars: Int { maxStars ?? 5 }
    var resolvedDuplicatesPerLevel: Int { max(1, duplicatesPerLevel ?? 2) }
    var resolvedLevelsPerStar: Int { max(1, levelsPerStar ?? 6) }
    var resolvedDamageGrowth: Double { damageGrowth ?? 1.08 }
    var resolvedTargeting: AbilityCardTargeting { targeting ?? .single }
    var isAOE: Bool { resolvedTargeting == .allEnemies }
    var isEventLimited: Bool {
        (isLimited ?? false)
            || source?.localizedCaseInsensitiveContains("event") == true
    }

    var eventSourceLabel: String {
        source ?? "Limited Event"
    }
}

func loadAbilityCards() -> [AbilityCardDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        AbilityCardDefinition.self,
        baseResources: ["ability_cards"],
        autoDiscoveredWhere: {
            $0.hasPrefix("ability_cards_") || $0.hasPrefix("summon_cards_")
        }
    )
}
