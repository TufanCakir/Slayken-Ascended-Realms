//
//  AbilityCardDefinition.swift
//  Slayken Ascended Realms
//

import Foundation

struct AbilityCardDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let image: String
    let element: String
    let damageMultiplier: Double
    let particleEffect: String
    let description: String
}

func loadAbilityCards() -> [AbilityCardDefinition] {
    JSONResourceLoader.loadArray(AbilityCardDefinition.self, resource: "ability_cards")
}
