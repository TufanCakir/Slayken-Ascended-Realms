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
    @Published var maps: [GameMap]
    @Published var backgrounds: [GameBackground]

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

    init() {
        print("🚀 GameState INIT")

        let loadedPlayer = loadPlayer()
        let loadedMaps = loadMaps()
        let loadedBackgrounds = loadBackgrounds()

        print("📦 Maps geladen:", loadedMaps.map { "\($0.id)-\($0.mapImage)" })
        print(
            "📦 BGs geladen:",
            loadedBackgrounds.map { "\($0.id)-\($0.image)" }
        )

        let defaultMap =
            loadedMaps.first ??
            GameMap(
                id: 0,
                name: "Default",
                mapImage: "map",
                difficulty: 1,
                enemy: CharacterStats(
                    name: "Dummy",
                    image: "acsended_riven",
                    hp: 100,
                    attack: 10
                ),
                story: []
            )
        let defaultBG =
            loadedBackgrounds.first
            ?? GameBackground(id: 0, name: "Default", image: "country")

        self.player = loadedPlayer
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
}
