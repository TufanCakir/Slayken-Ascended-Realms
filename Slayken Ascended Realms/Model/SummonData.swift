//
//  SummonData.swift
//  Slayken Ascended Realms
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
            hp: CGFloat(hp),
            attack: CGFloat(attack)
        )
    }
}

struct SummonBanner: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let image: String
    let cost: [CurrencyAmount]
    let rates: [SummonRate]
    let pool: [SummonPoolEntry]
}

struct SummonRate: Codable, Identifiable, Equatable {
    let rarity: Int
    let rate: Double

    var id: Int { rarity }
}

struct SummonPoolEntry: Codable, Identifiable, Equatable {
    let characterID: String
    let weight: Double

    var id: String { characterID }
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
