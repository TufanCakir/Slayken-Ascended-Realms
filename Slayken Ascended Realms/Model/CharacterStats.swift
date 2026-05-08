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
    let element: String?
    let hp: CGFloat
    let attack: CGFloat
    let attackSpeed: Double?

    init(
        name: String,
        image: String,
        model: String,
        battleModel: String? = nil,
        texture: String? = nil,
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
        self.element = element
        self.hp = hp
        self.attack = attack
        self.attackSpeed = attackSpeed
    }

    func withBattleModel(_ battleModel: String?) -> CharacterStats {
        CharacterStats(
            name: name,
            image: image,
            model: model,
            battleModel: battleModel,
            texture: texture,
            element: element,
            hp: hp,
            attack: attack,
            attackSpeed: attackSpeed
        )
    }
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
