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

    @Published var selectedMap: GameMap {
        didSet {
            print(
                "🟢 selectedMap geändert →",
                selectedMap.name,
                "|",
                selectedMap.mapImage
            )
        }
    }

    @Published var selectedBackground: GameBackground {
        didSet {
            print(
                "🟣 selectedBackground geändert →",
                selectedBackground.name,
                "|",
                selectedBackground.image
            )
        }
    }

    private let mapKey = "selectedMapID"
    private let bgKey = "selectedBackgroundID"
    private let characterKey = "selectedCharacterModel"

    init() {
        print("🚀 GameState INIT")

        let loadedCharacters = Self.loadAvailableCharacters()
        let loadedPlayer = loadedCharacters.first ?? loadBattlePlayer()
        let loadedMaps = loadMaps()
        let loadedBackgrounds = loadBackgrounds()

        print("📦 Maps geladen:", loadedMaps.map { "\($0.id)-\($0.mapImage)" })
        print(
            "📦 BGs geladen:",
            loadedBackgrounds.map { "\($0.id)-\($0.image)" }
        )

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

        print("⚙️ Default Map:", selectedMap.name, selectedMap.mapImage)
        print(
            "⚙️ Default BG:",
            selectedBackground.name,
            selectedBackground.image
        )

        loadSelections()
    }

    func loadSelections() {
        print("📥 Lade gespeicherte Auswahl...")

        if let savedMapID = UserDefaults.standard.object(forKey: mapKey) as? Int
        {
            print("🔎 gespeicherte Map ID:", savedMapID)

            if let map = maps.first(where: { $0.id == savedMapID }) {
                selectedMap = map
                print("✅ Map geladen:", map.name)
            } else {
                print("❌ Map ID nicht gefunden!")
            }
        } else {
            print("⚠️ keine gespeicherte Map")
        }

        if let savedBgID = UserDefaults.standard.object(forKey: bgKey) as? Int {
            print("🔎 gespeicherte BG ID:", savedBgID)

            if let bg = backgrounds.first(where: { $0.id == savedBgID }) {
                selectedBackground = bg
                print("✅ BG geladen:", bg.name)
            } else {
                print("❌ BG ID nicht gefunden!")
            }
        } else {
            print("⚠️ kein gespeicherter BG")
        }

        if let savedCharacterModel = UserDefaults.standard.string(forKey: characterKey) {
            print("🔎 gespeicherter Character:", savedCharacterModel)

            if let character = availableCharacters.first(where: { $0.model == savedCharacterModel }) {
                player = character
                print("✅ Character geladen:", character.name)
            } else {
                print("❌ Character nicht gefunden!")
            }
        } else {
            print("⚠️ kein gespeicherter Character")
        }
    }

    func saveMap(_ map: GameMap) {
        print("💾 SAVE MAP →", map.name, map.mapImage)

        selectedMap = map
        UserDefaults.standard.set(map.id, forKey: mapKey)

        print("💾 gespeichert unter ID:", map.id)
    }

    func saveBackground(_ background: GameBackground) {
        print("💾 SAVE BG →", background.name, background.image)

        selectedBackground = background
        UserDefaults.standard.set(background.id, forKey: bgKey)

        print("💾 gespeichert unter ID:", background.id)
    }

    func saveCharacter(_ character: CharacterStats) {
        print("💾 SAVE CHARACTER →", character.name, character.model)

        player = character
        UserDefaults.standard.set(character.model, forKey: characterKey)

        print("💾 gespeichert unter Model:", character.model)
    }

    private static func loadAvailableCharacters() -> [CharacterStats] {
        loadGamePlayers().map { character in
            character.withBattleModel(
                character.battleModel ?? makeBattleModelName(from: character.model)
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
