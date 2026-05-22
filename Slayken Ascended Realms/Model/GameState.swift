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
    @Published var currencies: [CurrencyDefinition]
    @Published var eventChapters: [GlobeEventChapter]
    @Published var summonCharacters: [SummonCharacter]
    @Published var summonBanners: [SummonBanner]
    @Published var abilityCards: [AbilityCardDefinition]
    @Published var particleEffects: [ParticleEffectDefinition]
    @Published var newsItems: [NewsItemDefinition]
    @Published var gifts: [GiftBoxDefinition]
    @Published var loginCampaigns: [LoginRewardCampaign]
    @Published var quests: [QuestDefinition]
    @Published var selectedBattle: GlobeBattle?
    @Published var activeEventChapterID: String?
    @Published var activeEventPointID: String?
    @Published var activeEventBattleID: String?
    @Published var activeRaidLobby: RaidLobbyState?
    @Published var activeRaidSession: ActiveRaidSession?

    var activeEventChapter: GlobeEventChapter? {
        eventChapters.first { $0.id == activeEventChapterID }
            ?? eventChapters.first
    }

    var activeEventPoint: GlobeEventPoint? {
        guard let activeEventChapter, let activeEventPointID else { return nil }
        return activeEventChapter.points.first { $0.id == activeEventPointID }
    }

    var activeBattle: GlobeBattle? {
        if let selectedBattle {
            return selectedBattle
        }

        guard let activeEventBattleID else { return nil }
        return
            eventChapters
            .flatMap(\.points)
            .flatMap(\.battles)
            .first { $0.id == activeEventBattleID }
    }

    var battlePlayer: CharacterStats {
        CharacterStats(
            name: player.name,
            image: player.image,
            model: player.model,
            battleModel: player.battleModel,
            texture: player.texture,
            element: player.element,
            hp: player.hp,
            attack: player.attack
        )
    }

    var activeMapTexture: String {
        activeEventPoint?.mapTexture
            ?? activeEventChapter?.mapTexture
            ?? "realm_country"
    }

    var activeGroundTexture: String {
        activeBattle?.groundTexture ?? activeMapTexture
    }

    var activeSkyboxTexture: String {
        activeBattle?.skyboxTexture ?? activeMapTexture
    }

    var activeBattleRewards: [CurrencyAmount] {
        activeBattle?.rewards ?? []
    }

    private let characterKey = "selectedCharacterModel"
    private let characterDataKey = "selectedCharacterData"
    private let eventChapterKey = "activeEventChapterID"
    private let eventPointKey = "activeEventPointID"
    private let eventBattleKey = "activeEventBattleID"

    init() {
        self.player = Self.placeholderCharacter
        self.availableCharacters = []
        self.currencies = []
        self.eventChapters = []
        self.summonCharacters = []
        self.summonBanners = []
        self.abilityCards = []
        self.particleEffects = []
        self.newsItems = []
        self.gifts = []
        self.loginCampaigns = []
        self.quests = []
        self.selectedBattle = nil
        self.activeEventChapterID = nil
        self.activeEventPointID = nil
        self.activeEventBattleID = nil
        self.activeRaidLobby = nil
        self.activeRaidSession = nil
    }

    func reloadContent() {
        availableCharacters = Self.loadAvailableCharacters()
        upsertAvailableCharacter(player)
        currencies = mergedCurrencyDefinitions()
        eventChapters = loadGlobeEventChapters()
        summonCharacters = loadSummonCharacters()
        summonBanners = loadSummonBanners()
        abilityCards = loadAbilityCards()
        particleEffects = loadParticleEffects()
        newsItems = loadNewsItems()
        gifts = loadGiftBoxDefinitions()
        loginCampaigns = loadLoginRewardCampaigns()
        quests = loadQuestDefinitions()

        loadSelections()
    }

    func loadSelections() {
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
        selectedBattle = nil
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
        selectedBattle = nil
        activeEventChapterID = chapter.id
        activeEventPointID = point.id
        activeEventBattleID = nil
        UserDefaults.standard.set(chapter.id, forKey: eventChapterKey)
        UserDefaults.standard.set(point.id, forKey: eventPointKey)
        UserDefaults.standard.removeObject(forKey: eventBattleKey)
    }

    func clearActiveEventPoint() {
        selectedBattle = nil
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

    func updateRaidLobby(_ lobby: RaidLobbyState?) {
        activeRaidLobby = lobby
        if lobby == nil {
            activeRaidSession = nil
        }
    }

    func updateRaidSession(_ session: ActiveRaidSession?) {
        activeRaidSession = session
        if session != nil {
            selectedBattle = nil
        }
    }

    func resetGameData() {
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

    private func upsertAvailableCharacter(_ character: CharacterStats) {
        if let index = availableCharacters.firstIndex(where: {
            $0.model == character.model
        }) {
            availableCharacters[index] = character
        } else {
            availableCharacters.append(character)
        }
    }

    private func mergedCurrencyDefinitions() -> [CurrencyDefinition] {
        var definitionsByCode = [String: CurrencyDefinition]()

        for currency in loadCurrencyDefinitions() {
            definitionsByCode[currency.code] = currency
        }

        for currency in loadRaidCurrencyDefinitions() {
            definitionsByCode[currency.code] = currency
        }

        return definitionsByCode.values.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.code < rhs.code
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private static let placeholderCharacter = CharacterStats(
        name: "Hero",
        image: "",
        model: "",
        hp: 100,
        attack: 10
    )

}
