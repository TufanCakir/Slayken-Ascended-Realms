//
//  AbilityCardDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

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

    var resolvedRarity: Int { rarity ?? resolvedMaxStars }
    var resolvedManaCost: Int { manaCost ?? 35 }
    var resolvedMaxLevel: Int { maxLevel ?? 30 }
    var resolvedMaxStars: Int { maxStars ?? 5 }
    var resolvedDuplicatesPerLevel: Int { max(1, duplicatesPerLevel ?? 2) }
    var resolvedLevelsPerStar: Int { max(1, levelsPerStar ?? 6) }
    var resolvedDamageGrowth: Double { damageGrowth ?? 1.08 }
}

func loadAbilityCards() -> [AbilityCardDefinition] {
    JSONResourceLoader.loadArray(
        AbilityCardDefinition.self,
        resource: "ability_cards"
    )
}
