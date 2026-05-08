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
    JSONResourceLoader.loadMergedIdentifiableArrays(
        GameMap.self,
        baseResources: ["maps"],
        autoDiscoveredWhere: {
            $0.hasPrefix("maps_") || $0.hasPrefix("game_map_")
        }
    )
}

func loadBackgrounds() -> [GameBackground] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        GameBackground.self,
        baseResources: ["backgrounds"],
        autoDiscoveredWhere: {
            $0.hasPrefix("backgrounds_") || $0.hasPrefix("game_background_")
        }
    )
}
