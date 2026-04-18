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
    @Published var currencies: [CurrencyDefinition]
    @Published var eventChapters: [GlobeEventChapter]
    @Published var summonCharacters: [SummonCharacter]
    @Published var summonBanners: [SummonBanner]
    @Published var selectedBattle: GlobeBattle?
    @Published var activeEventChapterID: String?
    @Published var activeEventPointID: String?

    var activeEventChapter: GlobeEventChapter? {
        eventChapters.first { $0.id == activeEventChapterID }
            ?? eventChapters.first
    }

    var activeEventPoint: GlobeEventPoint? {
        guard let activeEventChapter, let activeEventPointID else { return nil }
        return activeEventChapter.points.first { $0.id == activeEventPointID }
    }

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

    var activeGroundTexture: String {
        selectedBattle?.groundTexture ?? selectedMap.mapImage
    }

    var activeSkyboxTexture: String {
        selectedBattle?.skyboxTexture ?? selectedBackground.image
    }

    var activeBattleRewards: [CurrencyAmount] {
        selectedBattle?.rewards ?? []
    }

    private let mapKey = "selectedMapID"
    private let bgKey = "selectedBackgroundID"
    private let characterKey = "selectedCharacterModel"

    init() {
        let loadedCharacters = Self.loadAvailableCharacters()
        let loadedPlayer = loadedCharacters.first ?? loadBattlePlayer()
        let loadedMaps = loadMaps()
        let loadedBackgrounds = loadBackgrounds()
        let loadedCurrencies = loadCurrencyDefinitions()
        let loadedEventChapters = loadGlobeEventChapters()
        let loadedSummonCharacters = loadSummonCharacters()
        let loadedSummonBanners = loadSummonBanners()

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
        self.currencies = loadedCurrencies
        self.eventChapters = loadedEventChapters
        self.summonCharacters = loadedSummonCharacters
        self.summonBanners = loadedSummonBanners
        self.selectedBattle = nil
        self.activeEventChapterID = loadedEventChapters.first?.id
        self.activeEventPointID = nil
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

    func saveSummonedCharacter(
        _ character: SummonCharacter,
        selectedSkinID: String? = nil
    ) {
        saveCharacter(character.stats(selectedSkinID: selectedSkinID))
    }

    func selectEventChapter(_ chapter: GlobeEventChapter) {
        activeEventChapterID = chapter.id
        activeEventPointID = nil
    }

    func selectEventPoint(
        _ point: GlobeEventPoint,
        in chapter: GlobeEventChapter
    ) {
        activeEventChapterID = chapter.id
        activeEventPointID = point.id
    }

    func selectBattle(_ battle: GlobeBattle) {
        selectedBattle = battle
        if let location = eventLocation(for: battle.id) {
            activeEventChapterID = location.chapter.id
            activeEventPointID = location.point.id
        }
    }

    func clearBattleSelection() {
        selectedBattle = nil
    }

    private func eventLocation(for battleID: String) -> (
        chapter: GlobeEventChapter, point: GlobeEventPoint
    )? {
        for chapter in eventChapters {
            for point in chapter.points
            where point.battles.contains(where: { $0.id == battleID }) {
                return (chapter, point)
            }
        }
        return nil
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
