//
//  CharacterStats.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct CharacterStats: Codable {
    let name: String
    let image: String
    let hp: CGFloat
    let attack: CGFloat
}

func loadPlayer() -> CharacterStats {
    guard
        let url = Bundle.main.url(forResource: "player", withExtension: "json"),
        let data = try? Data(contentsOf: url),
        let player = try? JSONDecoder().decode(CharacterStats.self, from: data)
    else {
        return CharacterStats(
            name: "Default",
            image: "character1",
            hp: 100,
            attack: 10
        )
    }

    return player
}
