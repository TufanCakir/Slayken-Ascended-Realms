//
//  GameMap.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct GameMap: Identifiable, Codable {
    let id: Int
    let name: String
    let mapImage: String
    let difficulty: Int
    let enemy: CharacterStats
    let story: [StoryLine] 
}

struct GameBackground: Identifiable, Codable {
    let id: Int
    let name: String
    let image: String
}

func loadMaps() -> [GameMap] {
    guard let url = Bundle.main.url(forResource: "maps", withExtension: "json")
    else {
        print("❌ maps.json nicht im Bundle gefunden")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let maps = try JSONDecoder().decode([GameMap].self, from: data)
        print("✅ maps geladen:", maps.count)
        return maps
    } catch {
        print("❌ maps.json Decode Fehler:", error)
        return []
    }
}

func loadBackgrounds() -> [GameBackground] {
    guard
        let url = Bundle.main.url(
            forResource: "backgrounds",
            withExtension: "json"
        )
    else {
        print("❌ backgrounds.json nicht im Bundle gefunden")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let backgrounds = try JSONDecoder().decode(
            [GameBackground].self,
            from: data
        )
        print("✅ backgrounds geladen:", backgrounds.count)
        return backgrounds
    } catch {
        print("❌ backgrounds.json Decode Fehler:", error)
        return []
    }
}
