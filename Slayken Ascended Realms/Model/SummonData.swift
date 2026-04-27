//
//  SummonData.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

struct CharacterSkin: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let texture: String
    let summonImage: String?
}

struct SummonCharacter: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let summonImage: String
    let model: String
    let battleModel: String?
    let texture: String?
    let element: String?
    let rarity: Int
    let hp: Double
    let attack: Double
    let skins: [CharacterSkin]

    func stats(selectedSkinID: String? = nil) -> CharacterStats {
        let selectedSkin = skins.first { $0.id == selectedSkinID }
        return CharacterStats(
            name: name,
            image: selectedSkin?.summonImage ?? summonImage,
            model: model,
            battleModel: battleModel,
            texture: selectedSkin?.texture ?? texture,
            element: element,
            hp: CGFloat(hp),
            attack: CGFloat(attack)
        )
    }
}

struct SummonBanner: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String?
    let category: String?
    let image: String
    let minAscendedLevel: Int?
    let cost: [CurrencyAmount]
    let maxSummons: Int?
    let guarantee: SummonGuarantee?
    let rates: [SummonRate]
    let pool: [SummonPoolEntry]

    var requiredAscendedLevel: Int {
        max(1, minAscendedLevel ?? 1)
    }
}

struct SummonGuarantee: Codable, Equatable {
    let dropType: String?
    let rarity: Int?
    let appliesOnSummon: Int?
}

struct SummonRate: Codable, Identifiable, Equatable {
    let rarity: Int
    let rate: Double

    var id: Int { rarity }
}

struct SummonPoolEntry: Codable, Identifiable, Equatable {
    let characterID: String?
    let cardID: String?
    let weight: Double

    var id: String { characterID ?? cardID ?? UUID().uuidString }
}

func loadSummonCharacters() -> [SummonCharacter] {
    JSONResourceLoader.loadArray(
        SummonCharacter.self,
        resource: "summon_characters"
    )
}

func loadSummonBanners() -> [SummonBanner] {
    JSONResourceLoader.loadArray(SummonBanner.self, resource: "summon_banners")
}
