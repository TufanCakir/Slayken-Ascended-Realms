//
//  CharacterSkillTree.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct CharacterSkillNodeBonus: Codable, Hashable {
    let type: String
    let value: Double

    var resolvedType: String {
        normalizedSkillBonusType(type)
    }
}

struct CharacterSkillNodePosition: Codable, Hashable {
    let x: Double
    let y: Double
}

struct CharacterSkillTreePalette: Codable, Hashable {
    let selectorStartHex: String?
    let selectorEndHex: String?
    let panelStartHex: String?
    let panelEndHex: String?
    let resourceBarStartHex: String?
    let resourceBarEndHex: String?
    let connectionHex: String?
}

struct CharacterSkillNodePalette: Codable, Hashable {
    let fieldName: String?
    let fillStartHex: String?
    let fillEndHex: String?
    let lockedStartHex: String?
    let lockedEndHex: String?
    let masteredStartHex: String?
    let masteredEndHex: String?
    let accentHex: String?
}

struct CharacterSkillNodeDefinition: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let assetIcon: String?
    let maxRank: Int
    let costCurrency: String
    let costPerRank: Int
    let autoLearnPriority: Int?
    let position: CharacterSkillNodePosition
    let prerequisites: [String]
    let bonuses: [CharacterSkillNodeBonus]
    let palette: CharacterSkillNodePalette?

    var resolvedAutoLearnPriority: Int {
        autoLearnPriority ?? 999
    }
}

struct CharacterSkillTreeDefinition: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let sortOrder: Int?
    let palette: CharacterSkillTreePalette?
    let nodes: [CharacterSkillNodeDefinition]
}

struct CharacterSkillBonusTotals: Equatable {
    private var values: [String: Double] = [:]

    mutating func add(type: String, value: Double) {
        let resolvedType = normalizedSkillBonusType(type)
        values[resolvedType, default: 0] += value
    }

    func value(for type: String) -> Double {
        values[normalizedSkillBonusType(type), default: 0]
    }

    func statPercent(for stat: String) -> Double {
        value(for: "stat_\(normalizedSkillBonusKey(stat))_percent")
    }

    func damagePercent(for key: String) -> Double {
        value(for: "damage_\(normalizedSkillBonusKey(key))_percent")
    }

    func dropPercent(for key: String) -> Double {
        value(for: "drop_\(normalizedSkillBonusKey(key))_percent")
    }

    func regenPercent(for resource: String) -> Double {
        value(
            for: "resource_\(normalizedSkillBonusKey(resource))_regen_percent"
        )
    }

    var hpPercent: Double { statPercent(for: "hp") }
    var attackPercent: Double { statPercent(for: "attack") }
    var cardDamagePercent: Double {
        damagePercent(for: "cards") + damagePercent(for: "all")
    }
    var manaRegenPercent: Double { regenPercent(for: "mana") }
    var coinDropPercent: Double { dropPercent(for: "coins") }
    var crystalDropPercent: Double { dropPercent(for: "crystals") }
    var cardDropPercent: Double { dropPercent(for: "cards") }
}

func normalizedSkillBonusType(_ rawType: String) -> String {
    let normalized = normalizedSkillBonusKey(rawType)

    switch normalized {
    case "hp_percent":
        return "stat_hp_percent"
    case "attack_percent":
        return "stat_attack_percent"
    case "card_damage_percent":
        return "damage_cards_percent"
    case "mana_regen_percent":
        return "resource_mana_regen_percent"
    case "coin_drop_percent":
        return "drop_coins_percent"
    case "crystal_drop_percent":
        return "drop_crystals_percent"
    case "card_drop_percent":
        return "drop_cards_percent"
    default:
        return normalized
    }
}

func normalizedSkillBonusKey(_ rawValue: String) -> String {
    rawValue
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "-", with: "_")
}

func loadCharacterSkillTrees() -> [CharacterSkillTreeDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        CharacterSkillTreeDefinition.self,
        baseResources: ["skill_tree"],
        autoDiscoveredWhere: {
            $0.hasPrefix("skill_tree_") || $0.hasPrefix("character_skill_tree_")
        }
    )
    .sorted(by: compareSkillTrees)
}

private func compareSkillTrees(
    _ lhs: CharacterSkillTreeDefinition,
    _ rhs: CharacterSkillTreeDefinition
) -> Bool {
    if lhs.sortOrder != rhs.sortOrder {
        return (lhs.sortOrder ?? inferredSkillTreeOrder(from: lhs.id))
            < (rhs.sortOrder ?? inferredSkillTreeOrder(from: rhs.id))
    }

    return lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        == .orderedAscending
}

private func inferredSkillTreeOrder(from id: String) -> Int {
    let digits = id.compactMap(\.wholeNumberValue)
    guard !digits.isEmpty else {
        return 999
    }

    return digits.reduce(0) { partialResult, digit in
        (partialResult * 10) + digit
    }
}
