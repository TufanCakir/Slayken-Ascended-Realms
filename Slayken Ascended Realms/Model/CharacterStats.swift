//
//  CharacterStats.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

struct CharacterStats: Codable {
    let name: String
    let image: String
    let model: String
    let texture: String?
    let hp: CGFloat
    let attack: CGFloat

    init(
        name: String,
        image: String,
        model: String,
        texture: String? = nil,
        hp: CGFloat,
        attack: CGFloat
    ) {
        self.name = name
        self.image = image
        self.model = model
        self.texture = texture
        self.hp = hp
        self.attack = attack
    }
}

func loadGamePlayer() -> CharacterStats {
    loadCharacter(named: "game_player")
}

func loadBattlePlayer() -> CharacterStats {
    loadCharacter(named: "battle_player")
}

func loadPlayer() -> CharacterStats {
    loadBattlePlayer()
}

private func loadCharacter(named resourceName: String) -> CharacterStats {
    guard
        let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let player = try? JSONDecoder().decode(CharacterStats.self, from: data)
    else {
        return CharacterStats(
            name: "Default",
            image: "character1",
            model: "riven",
            hp: 100,
            attack: 10
        )
    }

    return player
}
