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
    @Published var abilityCards: [AbilityCardDefinition]
    @Published var particleEffects: [ParticleEffectDefinition]
    @Published var selectedBattle: GlobeBattle?
    @Published var activeEventChapterID: String?
    @Published var activeEventPointID: String?
    @Published var activeEventBattleID: String?

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
            element: player.element,
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
    private let characterDataKey = "selectedCharacterData"
    private let eventChapterKey = "activeEventChapterID"
    private let eventPointKey = "activeEventPointID"
    private let eventBattleKey = "activeEventBattleID"

    init() {
        let loadedCharacters = Self.loadAvailableCharacters()
        let loadedPlayer = loadedCharacters.first ?? loadBattlePlayer()
        let loadedMaps = loadMaps()
        let loadedBackgrounds = loadBackgrounds()
        let loadedCurrencies = loadCurrencyDefinitions()
        let loadedEventChapters = loadGlobeEventChapters()
        let loadedSummonCharacters = loadSummonCharacters()
        let loadedSummonBanners = loadSummonBanners()
        let loadedAbilityCards = loadAbilityCards()
        let loadedParticleEffects = loadParticleEffects()

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
        self.abilityCards = loadedAbilityCards
        self.particleEffects = loadedParticleEffects
        self.selectedBattle = nil
        self.activeEventChapterID = loadedEventChapters.first?.id
        self.activeEventPointID = nil
        self.activeEventBattleID = nil
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

        if let savedCharacterData = UserDefaults.standard.data(
            forKey: characterDataKey
        ),
            let character = try? JSONDecoder().decode(
                CharacterStats.self,
                from: savedCharacterData
            )
        {
            player = character
            upsertAvailableCharacter(character)
        } else if let savedCharacterModel = UserDefaults.standard.string(
            forKey: characterKey
        ) {
            if let character = availableCharacters.first(where: {
                $0.model == savedCharacterModel
            }) {
                player = character
            }
        }

        if let savedChapterID = UserDefaults.standard.string(
            forKey: eventChapterKey
        ), eventChapters.contains(where: { $0.id == savedChapterID }) {
            activeEventChapterID = savedChapterID
        }

        if let savedPointID = UserDefaults.standard.string(
            forKey: eventPointKey
        ),
            let chapter = activeEventChapter,
            chapter.points.contains(where: { $0.id == savedPointID })
        {
            activeEventPointID = savedPointID
        } else {
            activeEventPointID = nil
        }

        if let savedBattleID = UserDefaults.standard.string(
            forKey: eventBattleKey
        ),
            let point = activeEventPoint,
            point.battles.contains(where: { $0.id == savedBattleID })
        {
            activeEventBattleID = savedBattleID
        } else {
            activeEventBattleID = nil
        }
    }

    func saveCharacter(_ character: CharacterStats) {
        player = character
        upsertAvailableCharacter(character)
        UserDefaults.standard.set(character.model, forKey: characterKey)
        if let data = try? JSONEncoder().encode(character) {
            UserDefaults.standard.set(data, forKey: characterDataKey)
        }
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
        activeEventBattleID = nil
        UserDefaults.standard.set(chapter.id, forKey: eventChapterKey)
        UserDefaults.standard.removeObject(forKey: eventPointKey)
        UserDefaults.standard.removeObject(forKey: eventBattleKey)
    }

    func selectEventPoint(
        _ point: GlobeEventPoint,
        in chapter: GlobeEventChapter
    ) {
        activeEventChapterID = chapter.id
        activeEventPointID = point.id
        activeEventBattleID = nil
        UserDefaults.standard.set(chapter.id, forKey: eventChapterKey)
        UserDefaults.standard.set(point.id, forKey: eventPointKey)
        UserDefaults.standard.removeObject(forKey: eventBattleKey)
    }

    func clearActiveEventPoint() {
        activeEventPointID = nil
        activeEventBattleID = nil
        UserDefaults.standard.removeObject(forKey: eventPointKey)
        UserDefaults.standard.removeObject(forKey: eventBattleKey)
        if let activeEventChapterID {
            UserDefaults.standard.set(
                activeEventChapterID,
                forKey: eventChapterKey
            )
        }
    }

    func selectBattle(_ battle: GlobeBattle) {
        selectedBattle = battle
        if let location = eventLocation(for: battle.id) {
            activeEventChapterID = location.chapter.id
            activeEventPointID = location.point.id
            activeEventBattleID = battle.id
            UserDefaults.standard.set(
                location.chapter.id,
                forKey: eventChapterKey
            )
            UserDefaults.standard.set(location.point.id, forKey: eventPointKey)
            UserDefaults.standard.set(battle.id, forKey: eventBattleKey)
        }
    }

    func clearBattleSelection() {
        selectedBattle = nil
    }

    func resetGameData() {
        UserDefaults.standard.removeObject(forKey: mapKey)
        UserDefaults.standard.removeObject(forKey: bgKey)
        UserDefaults.standard.removeObject(forKey: characterKey)
        UserDefaults.standard.removeObject(forKey: characterDataKey)
        UserDefaults.standard.removeObject(forKey: eventChapterKey)
        UserDefaults.standard.removeObject(forKey: eventPointKey)
        UserDefaults.standard.removeObject(forKey: eventBattleKey)

        selectedBattle = nil
        activeEventChapterID = eventChapters.first?.id
        activeEventPointID = nil
        activeEventBattleID = nil

        if let defaultCharacter = availableCharacters.first {
            player = defaultCharacter
        }
        if let defaultMap = maps.first {
            selectedMap = defaultMap
        }
        if let defaultBackground = backgrounds.first {
            selectedBackground = defaultBackground
        }
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
        let builtInCharacters = loadGamePlayers().map { character in
            character.withBattleModel(
                character.battleModel
                    ?? makeBattleModelName(from: character.model)
            )
        }

        let starterClassCharacters = loadCharacterClassDefinitions().flatMap {
            definition -> [CharacterStats] in
            guard definition.requiredAscendedLevel <= 1 else { return [] }
            return definition.variants.map { variant in
                variant.makeCharacter(named: definition.defaultName)
            }
        }

        return builtInCharacters + starterClassCharacters
    }

    private static func makeBattleModelName(from modelName: String) -> String {
        if modelName.hasSuffix("_animation") {
            return String(modelName.dropLast("_animation".count))
        }
        return modelName
    }

    private func upsertAvailableCharacter(_ character: CharacterStats) {
        if let index = availableCharacters.firstIndex(where: {
            $0.model == character.model
        }) {
            availableCharacters[index] = character
        } else {
            availableCharacters.append(character)
        }
    }
}
