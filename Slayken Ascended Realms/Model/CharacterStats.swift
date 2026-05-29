//
//  CharacterStats.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

struct CharacterStats: Codable, Equatable, Identifiable {
    var id: String { model }

    let name: String
    let image: String
    let model: String
    let battleModel: String?
    let texture: String?
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
    let element: String?
    let hp: CGFloat
    let attack: CGFloat
    let attackSpeed: Double?

    private enum CodingKeys: String, CodingKey {
        case enemyID
        case level
        case name
        case image
        case model
        case battleModel
        case texture
        case materialColor
        case emissionColor
        case emissionIntensity
        case roughness
        case metalness
        case auraColor
        case auraIntensity
        case auraRadius
        case particleEffect
        case shadowColor
        case shadowOpacity
        case element
        case hp
        case attack
        case attackSpeed
    }

    init(
        name: String,
        image: String,
        model: String,
        battleModel: String? = nil,
        texture: String? = nil,
        materialColor: String? = nil,
        emissionColor: String? = nil,
        emissionIntensity: Double? = nil,
        roughness: Double? = nil,
        metalness: Double? = nil,
        auraColor: String? = nil,
        auraIntensity: Double? = nil,
        auraRadius: Double? = nil,
        particleEffect: String? = nil,
        shadowColor: String? = nil,
        shadowOpacity: Double? = nil,
        element: String? = nil,
        hp: CGFloat,
        attack: CGFloat,
        attackSpeed: Double? = nil
    ) {
        self.name = name
        self.image = image
        self.model = model
        self.battleModel = battleModel
        self.texture = texture
        self.materialColor = materialColor
        self.emissionColor = emissionColor
        self.emissionIntensity = emissionIntensity
        self.roughness = roughness
        self.metalness = metalness
        self.auraColor = auraColor
        self.auraIntensity = auraIntensity
        self.auraRadius = auraRadius
        self.particleEffect = particleEffect
        self.shadowColor = shadowColor
        self.shadowOpacity = shadowOpacity
        self.element = element
        self.hp = hp
        self.attack = attack
        self.attackSpeed = attackSpeed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let enemyID = try container.decodeIfPresent(
            String.self,
            forKey: .enemyID
        )
        let enemyDefinition = enemyID.flatMap { lookupEnemyDefinition(id: $0) }
        let level = max(
            1,
            try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        )
        let hpLevelScale = pow(1.035, Double(level - 1))
        let attackLevelScale = pow(1.025, Double(level - 1))

        name =
            try container.decodeIfPresent(String.self, forKey: .name)
            ?? enemyDefinition?.name
            ?? enemyID
            ?? "Unknown Enemy"
        image =
            try container.decodeIfPresent(String.self, forKey: .image)
            ?? enemyDefinition?.image
            ?? "sar_dragon"
        model =
            try container.decodeIfPresent(String.self, forKey: .model)
            ?? enemyDefinition?.model
            ?? enemyID
            ?? "unknown_enemy"
        battleModel =
            try container.decodeIfPresent(String.self, forKey: .battleModel)
            ?? enemyDefinition?.battleModel
        texture =
            try container.decodeIfPresent(String.self, forKey: .texture)
            ?? enemyDefinition?.texture
        materialColor = try container.decodeIfPresent(
            String.self,
            forKey: .materialColor
        )
        emissionColor = try container.decodeIfPresent(
            String.self,
            forKey: .emissionColor
        )
        emissionIntensity = try container.decodeIfPresent(
            Double.self,
            forKey: .emissionIntensity
        )
        roughness = try container.decodeIfPresent(Double.self, forKey: .roughness)
        metalness = try container.decodeIfPresent(Double.self, forKey: .metalness)
        auraColor = try container.decodeIfPresent(String.self, forKey: .auraColor)
        auraIntensity = try container.decodeIfPresent(
            Double.self,
            forKey: .auraIntensity
        )
        auraRadius = try container.decodeIfPresent(Double.self, forKey: .auraRadius)
        particleEffect = try container.decodeIfPresent(
            String.self,
            forKey: .particleEffect
        )
        shadowColor = try container.decodeIfPresent(String.self, forKey: .shadowColor)
        shadowOpacity = try container.decodeIfPresent(
            Double.self,
            forKey: .shadowOpacity
        )
        element =
            try container.decodeIfPresent(String.self, forKey: .element)
            ?? enemyDefinition?.element
        hp =
            (try container.decodeIfPresent(CGFloat.self, forKey: .hp)
                ?? enemyDefinition?.hp
                ?? 100) * CGFloat(hpLevelScale)
        attack =
            (try container.decodeIfPresent(CGFloat.self, forKey: .attack)
                ?? enemyDefinition?.attack
                ?? 10) * CGFloat(attackLevelScale)
        attackSpeed =
            try container.decodeIfPresent(Double.self, forKey: .attackSpeed)
            ?? enemyDefinition?.attackSpeed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(image, forKey: .image)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(battleModel, forKey: .battleModel)
        try container.encodeIfPresent(texture, forKey: .texture)
        try container.encodeIfPresent(materialColor, forKey: .materialColor)
        try container.encodeIfPresent(emissionColor, forKey: .emissionColor)
        try container.encodeIfPresent(emissionIntensity, forKey: .emissionIntensity)
        try container.encodeIfPresent(roughness, forKey: .roughness)
        try container.encodeIfPresent(metalness, forKey: .metalness)
        try container.encodeIfPresent(auraColor, forKey: .auraColor)
        try container.encodeIfPresent(auraIntensity, forKey: .auraIntensity)
        try container.encodeIfPresent(auraRadius, forKey: .auraRadius)
        try container.encodeIfPresent(particleEffect, forKey: .particleEffect)
        try container.encodeIfPresent(shadowColor, forKey: .shadowColor)
        try container.encodeIfPresent(shadowOpacity, forKey: .shadowOpacity)
        try container.encodeIfPresent(element, forKey: .element)
        try container.encode(hp, forKey: .hp)
        try container.encode(attack, forKey: .attack)
        try container.encodeIfPresent(attackSpeed, forKey: .attackSpeed)
    }

    func withBattleModel(_ battleModel: String?) -> CharacterStats {
        CharacterStats(
            name: name,
            image: image,
            model: model,
            battleModel: battleModel,
            texture: texture,
            materialColor: materialColor,
            emissionColor: emissionColor,
            emissionIntensity: emissionIntensity,
            roughness: roughness,
            metalness: metalness,
            auraColor: auraColor,
            auraIntensity: auraIntensity,
            auraRadius: auraRadius,
            particleEffect: particleEffect,
            shadowColor: shadowColor,
            shadowOpacity: shadowOpacity,
            element: element,
            hp: hp,
            attack: attack,
            attackSpeed: attackSpeed
        )
    }
}

struct EnemyDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let image: String
    let model: String
    let battleModel: String?
    let texture: String?
    let hp: CGFloat
    let attack: CGFloat
    let attackSpeed: Double?
    let element: String?
    let role: String?
}

func loadEnemyDefinitions() -> [EnemyDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        EnemyDefinition.self,
        baseResources: ["enemies"],
        autoDiscoveredWhere: {
            $0.hasPrefix("enemies_") || $0.hasPrefix("enemy_")
        }
    )
}

private func lookupEnemyDefinition(id: String) -> EnemyDefinition? {
    loadEnemyDefinitions().first { $0.id == id || $0.model == id }
}

func loadGamePlayer() -> CharacterStats {
    loadGamePlayers().first ?? defaultPlayer()
}

func loadGamePlayers() -> [CharacterStats] {
    loadCharacters(named: "game_player")
}

func loadBattlePlayer() -> CharacterStats {
    loadCharacters(named: "battle_player").first ?? defaultPlayer()
}

private func loadCharacters(named resourceName: String) -> [CharacterStats] {
    guard let data = JSONResourceLoader.loadData(resource: resourceName) else {
        return []
    }

    let decoder = JSONDecoder()

    if let players = try? decoder.decode([CharacterStats].self, from: data) {
        return players
    }

    if let player = try? decoder.decode(CharacterStats.self, from: data) {
        return [player]
    }

    return []
}

private func defaultPlayer() -> CharacterStats {
    CharacterStats(
        name: "Zaron",
        image: "preview_zaron",
        model: "zaron",
        texture: "texture_zaron_original",
        hp: 300,
        attack: 300
    )
}
