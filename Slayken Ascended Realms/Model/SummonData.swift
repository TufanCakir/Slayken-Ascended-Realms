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
    let materialColor: String?
    let emissionColor: String?
    let emissionIntensity: Double?
    let roughness: Double?
    let metalness: Double?
    let auraColor: String?
    let auraIntensity: Double?
    let auraRadius: Double?
    let particleEffect: String?
    let shadowColor: String?
    let shadowOpacity: Double?
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
            materialColor: selectedSkin?.materialColor,
            emissionColor: selectedSkin?.emissionColor,
            emissionIntensity: selectedSkin?.emissionIntensity,
            roughness: selectedSkin?.roughness,
            metalness: selectedSkin?.metalness,
            auraColor: selectedSkin?.auraColor,
            auraIntensity: selectedSkin?.auraIntensity,
            auraRadius: selectedSkin?.auraRadius,
            particleEffect: selectedSkin?.particleEffect,
            shadowColor: selectedSkin?.shadowColor,
            shadowOpacity: selectedSkin?.shadowOpacity,
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
    let endsAt: String?
    let minAscendedLevel: Int?
    let cost: [CurrencyAmount]
    let multiSummonCount: Int?
    let maxSummons: Int?
    let guarantee: SummonGuarantee?
    let rates: [SummonRate]
    let pool: [SummonPoolEntry]

    var requiredAscendedLevel: Int {
        max(1, minAscendedLevel ?? 1)
    }

    var resolvedMultiSummonCount: Int {
        max(1, multiSummonCount ?? 1)
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
    let skinID: String?
    let cardID: String?
    let weight: Double

    var id: String {
        if let characterID, let skinID {
            return "\(characterID):\(skinID)"
        }
        if let characterID {
            return characterID
        }
        if let cardID {
            return cardID
        }
        return "empty-pool-entry-\(weight)"
    }
}

func loadSummonCharacters() -> [SummonCharacter] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        SummonCharacter.self,
        baseResources: ["summon_characters"],
        autoDiscoveredWhere: {
            $0.hasPrefix("summon_characters_")
                || $0.hasPrefix("summon_character_")
        }
    )
}

func loadSummonBanners() -> [SummonBanner] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        SummonBanner.self,
        baseResources: ["summon_banners"],
        autoDiscoveredWhere: {
            $0.hasPrefix("summon_banners_")
                || $0.hasPrefix("summon_banner_")
        }
    )
    .filter { EventDateSupport.isActive(endsAt: $0.endsAt) }
}
