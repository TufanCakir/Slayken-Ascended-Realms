//
//  BattleComboDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 29.05.26.
//

import Foundation

struct BattleComboDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String?
    let description: String?
    let inputSequence: [String]?
    let isDefault: Bool?
    let sortOrder: Int?
    let comboWindow: Double?
    let resetAfter: Double?
    let steps: [BattleComboStepDefinition]

    var displayName: String {
        name ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var displayDescription: String {
        description ?? "Combo-Angriff"
    }

    var resolvedInputSequence: [String] {
        let explicitInputs = inputSequence?.filter { !$0.isEmpty } ?? []
        if !explicitInputs.isEmpty {
            return explicitInputs
        }

        return steps.map { $0.resolvedInput }
    }

    var resolvedComboWindow: Double {
        max(0.35, comboWindow ?? 1.2)
    }

    var resolvedResetAfter: Double {
        max(resolvedComboWindow, resetAfter ?? 1.8)
    }
}

struct BattleComboStepDefinition: Codable, Identifiable, Equatable {
    let id: String
    let input: String?
    let label: String?
    let style: String?
    let damageMultiplier: Double?
    let hitDelay: Double?
    let holdDuration: Double?
    let slowMotion: Bool?
    let particleEffect: String?

    var resolvedStyle: BattleComboStyle {
        BattleComboStyle(rawValue: style ?? "") ?? .dash
    }

    var displayLabel: String {
        label ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var resolvedInput: String {
        input ?? "tap"
    }

    var resolvedDamageMultiplier: Double {
        max(0.1, damageMultiplier ?? 1.0)
    }

    var resolvedHitDelay: Double {
        max(0.05, hitDelay ?? 0.22)
    }

    var resolvedHoldDuration: Double {
        max(0, holdDuration ?? 0.18)
    }

    var isSlowMotion: Bool {
        slowMotion ?? false
    }
}

enum BattleComboStyle: String, Codable {
    case dash
    case slashRight
    case slashLeft
    case slashDown
    case slashUp
    case heavy
    case finisher
}

func loadBattleComboDefinitions() -> [BattleComboDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        BattleComboDefinition.self,
        baseResources: ["battle_combos"],
        autoDiscoveredWhere: {
            $0.hasPrefix("battle_combos_")
                || $0.hasPrefix("battle_combo_")
        },
        sort: {
            ($0.sortOrder ?? 999) < ($1.sortOrder ?? 999)
        }
    )
}
