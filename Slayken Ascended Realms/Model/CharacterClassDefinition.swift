//
//  CharacterClassDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

struct CharacterClassDefinition: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let defaultName: String
    let category: CharacterClassCategory
    let minAscendedLevel: Int?
    let variants: [CharacterClassVariant]

    var defaultVariant: CharacterClassVariant? {
        variants.first
    }

    var requiredAscendedLevel: Int {
        max(1, minAscendedLevel ?? 1)
    }

    var isHeroClass: Bool {
        category == .hero
    }
}

enum CharacterClassCategory: String, Codable, Hashable {
    case standard
    case hero
}

struct CharacterClassVariant: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let image: String
    let model: String
    let battleModel: String
    let texture: String?
    let element: String
    let hp: CGFloat
    let attack: CGFloat
    let previewTransform: CharacterPreviewTransform?

    func makeCharacter(named name: String) -> CharacterStats {
        CharacterStats(
            name: name,
            image: image,
            model: model,
            battleModel: battleModel,
            texture: texture,
            element: element,
            hp: hp,
            attack: attack
        )
    }
}

struct CharacterPreviewTransform: Codable, Hashable {
    let pitchDegrees: Double?
    let yawDegrees: Double?
    let rollDegrees: Double?
    let scaleMultiplier: Double?
    let verticalOffset: Double?

    static let identity = CharacterPreviewTransform(
        pitchDegrees: nil,
        yawDegrees: nil,
        rollDegrees: nil,
        scaleMultiplier: nil,
        verticalOffset: nil
    )
}

func loadCharacterClassDefinitions() -> [CharacterClassDefinition] {
    JSONResourceLoader.loadArray(
        CharacterClassDefinition.self,
        resource: "character_classes"
    )
}
