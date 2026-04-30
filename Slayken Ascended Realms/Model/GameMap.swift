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
    do {
        guard let data = JSONResourceLoader.loadData(resource: "maps") else {
            return []
        }
        let maps = try JSONDecoder().decode([GameMap].self, from: data)
        return maps
    } catch {
        return []
    }
}

func loadBackgrounds() -> [GameBackground] {
    do {
        guard let data = JSONResourceLoader.loadData(resource: "backgrounds") else {
            return []
        }
        let backgrounds = try JSONDecoder().decode(
            [GameBackground].self,
            from: data
        )
        return backgrounds
    } catch {
        return []
    }
}
