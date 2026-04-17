//
//  GameState.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import SwiftUI

final class GameState: ObservableObject {
    @Published var player: CharacterStats
    @Published var availableCharacters: [CharacterStats]
    @Published var maps: [GameMap]
    @Published var backgrounds: [GameBackground]

    var battlePlayer: CharacterStats {
        CharacterStats(
            name: player.name,
            image: player.image,
            model: player.battleModel ?? player.model,
            battleModel: player.battleModel,
            texture: player.texture,
            hp: player.hp,
            attack: player.attack
        )
    }

    @Published var selectedMap: GameMap
    @Published var selectedBackground: GameBackground

    private let mapKey = "selectedMapID"
    private let bgKey = "selectedBackgroundID"
    private let characterKey = "selectedCharacterModel"

    init() {
        let loadedCharacters = Self.loadAvailableCharacters()
        let loadedPlayer = loadedCharacters.first ?? loadBattlePlayer()
        let loadedMaps = loadMaps()
        let loadedBackgrounds = loadBackgrounds()

        let defaultMap =
            loadedMaps.first
            ?? GameMap(
                id: 0,
                name: "Default",
                mapImage: "map",
                difficulty: 1,
                enemy: CharacterStats(
                    name: "Dummy",
                    image: "acsended_riven",
                    model: "riven",
                    hp: 100,
                    attack: 10
                ),
                story: []
            )
        let defaultBG =
            loadedBackgrounds.first
            ?? GameBackground(id: 0, name: "Default", image: "country")

        self.player = loadedPlayer
        self.availableCharacters = loadedCharacters
        self.maps = loadedMaps
        self.backgrounds = loadedBackgrounds
        self.selectedMap = defaultMap
        self.selectedBackground = defaultBG

        loadSelections()
    }

    func loadSelections() {
        if let savedMapID = UserDefaults.standard.object(forKey: mapKey) as? Int
        {
            if let map = maps.first(where: { $0.id == savedMapID }) {
                selectedMap = map
            }
        }

        if let savedBgID = UserDefaults.standard.object(forKey: bgKey) as? Int {
            if let bg = backgrounds.first(where: { $0.id == savedBgID }) {
                selectedBackground = bg
            }
        }

        if let savedCharacterModel = UserDefaults.standard.string(
            forKey: characterKey
        ) {
            if let character = availableCharacters.first(where: {
                $0.model == savedCharacterModel
            }) {
                player = character
            }
        }
    }

    func saveMap(_ map: GameMap) {
        selectedMap = map
        UserDefaults.standard.set(map.id, forKey: mapKey)
    }

    func saveBackground(_ background: GameBackground) {
        selectedBackground = background
        UserDefaults.standard.set(background.id, forKey: bgKey)
    }

    func saveCharacter(_ character: CharacterStats) {
        player = character
        UserDefaults.standard.set(character.model, forKey: characterKey)
    }

    private static func loadAvailableCharacters() -> [CharacterStats] {
        loadGamePlayers().map { character in
            character.withBattleModel(
                character.battleModel
                    ?? makeBattleModelName(from: character.model)
            )
        }
    }

    private static func makeBattleModelName(from modelName: String) -> String {
        if modelName.hasSuffix("_animation") {
            return String(modelName.dropLast("_animation".count))
        }
        return modelName
    }
}
