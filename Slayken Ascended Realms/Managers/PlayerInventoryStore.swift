//
//  PlayerInventoryStore.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation
import SwiftData

@MainActor
enum PlayerInventoryStore {
    private static let battleVictoryCounterKey = "battle_victories"
    private static let monsterKillCounterKey = "monster_kills"

    static func ensureBalances(
        for currencies: [CurrencyDefinition],
        in context: ModelContext
    ) {
        for currency in currencies {
            if balance(for: currency.code, in: context) == nil {
                context.insert(
                    PlayerCurrencyBalance(code: currency.code, amount: 0)
                )
            }
        }
        save(context)
    }

    static func balance(for code: String, in context: ModelContext)
        -> PlayerCurrencyBalance?
    {
        let descriptor = FetchDescriptor<PlayerCurrencyBalance>(
            predicate: #Predicate { $0.code == code }
        )
        return try? context.fetch(descriptor).first
    }

    static func amount(for code: String, in context: ModelContext) -> Int {
        balance(for: code, in: context)?.amount ?? 0
    }

    static func add(_ rewards: [CurrencyAmount], in context: ModelContext) {
        for reward in rewards where reward.amount != 0 {
            let existing = balance(for: reward.currency, in: context)
            let balance =
                existing ?? PlayerCurrencyBalance(code: reward.currency)
            if existing == nil {
                context.insert(balance)
            }
            balance.amount += reward.amount

            if reward.amount > 0 {
                incrementQuestCounter(
                    currencyEarnedCounterKey(for: reward.currency),
                    by: reward.amount,
                    in: context,
                    shouldSave: false
                )
            }
        }
        save(context)
    }

    @discardableResult
    static func addBattleRewards(
        _ rewards: [CurrencyAmount],
        in context: ModelContext,
        limits: BattleRewardLimitDefinition? = nil,
        now: Date = .now
    ) -> [CurrencyAmount] {
        let baseConfiguration = loadBattleResourceConfiguration()
        let configuration = baseConfiguration.resolved(
            forAscendedLevel: accountProgress(in: context).level
        )
        let state = battleResourceState(
            configuration: configuration,
            in: context,
            now: now
        )
        let resolvedLimits =
            limits?.resolvedLimits(using: configuration)
            ?? BattleRewardLimitValues(
                coins: configuration.coinLimit.maximum,
                crystals: configuration.crystalLimit.maximum
            )

        let filteredRewards = rewards.compactMap { reward -> CurrencyAmount? in
            switch reward.currency {
            case "coins":
                let remaining = max(
                    0,
                    min(state.availableCoinsLimit, resolvedLimits.coins)
                )
                let allowedAmount = min(reward.amount, remaining)
                guard allowedAmount > 0 else { return nil }
                state.availableCoinsLimit -= allowedAmount
                return CurrencyAmount(
                    currency: reward.currency,
                    amount: allowedAmount
                )
            case "crystals":
                let remaining = max(
                    0,
                    min(state.availableCrystalsLimit, resolvedLimits.crystals)
                )
                let allowedAmount = min(reward.amount, remaining)
                guard allowedAmount > 0 else { return nil }
                state.availableCrystalsLimit -= allowedAmount
                return CurrencyAmount(
                    currency: reward.currency,
                    amount: allowedAmount
                )
            default:
                return reward
            }
        }

        add(filteredRewards, in: context)
        save(context)
        return filteredRewards
    }

    static func dailyBattleFarmStatus(
        in context: ModelContext,
        now: Date = .now
    ) -> BattleResourceStatus {
        let configuration = loadBattleResourceConfiguration().resolved(
            forAscendedLevel: accountProgress(in: context).level
        )
        let state = battleResourceState(
            configuration: configuration,
            in: context,
            now: now
        )

        return BattleResourceStatus(
            energy: state.currentEnergy,
            energyMaximum: configuration.energy.maximum,
            energyCostPerBattle: configuration.energy.costPerBattle,
            energyRegenerationPerMinute: configuration.energy
                .regenerationPerMinute,
            availableCoinsLimit: state.availableCoinsLimit,
            coinsLimitMaximum: configuration.coinLimit.maximum,
            coinsRegenerationPerMinute: configuration.coinLimit
                .regenerationPerMinute,
            availableCrystalsLimit: state.availableCrystalsLimit,
            crystalsLimitMaximum: configuration.crystalLimit.maximum,
            crystalsRegenerationPerMinute: configuration.crystalLimit
                .regenerationPerMinute
        )
    }

    static func canStartBattle(
        in context: ModelContext,
        now: Date = .now
    ) -> Bool {
        let status = dailyBattleFarmStatus(in: context, now: now)
        return status.energy >= status.energyCostPerBattle
    }

    @discardableResult
    static func consumeBattleEnergyForStart(
        in context: ModelContext,
        now: Date = .now
    ) -> Bool {
        let configuration = loadBattleResourceConfiguration().resolved(
            forAscendedLevel: accountProgress(in: context).level
        )
        let state = battleResourceState(
            configuration: configuration,
            in: context,
            now: now
        )
        let energyCost = max(0, configuration.energy.costPerBattle)
        guard state.currentEnergy >= energyCost else { return false }
        state.currentEnergy -= energyCost
        save(context)
        return true
    }

    static func canSpend(_ cost: [CurrencyAmount], in context: ModelContext)
        -> Bool
    {
        cost.allSatisfy { amount(for: $0.currency, in: context) >= $0.amount }
    }

    static func spend(_ cost: [CurrencyAmount], in context: ModelContext)
        -> Bool
    {
        guard canSpend(cost, in: context) else { return false }
        for item in cost {
            balance(for: item.currency, in: context)?.amount -= item.amount
        }
        save(context)
        return true
    }

    static func own(characterID: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<OwnedSummonCharacter>(
            predicate: #Predicate { $0.characterID == characterID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func addOwned(characterID: String, in context: ModelContext) {
        guard !own(characterID: characterID, in: context) else { return }
        context.insert(OwnedSummonCharacter(characterID: characterID))
        save(context)
    }

    static func ownsSkin(
        characterID: String,
        skinID: String,
        in context: ModelContext
    ) -> Bool {
        let key = "\(characterID):\(skinID)"
        let descriptor = FetchDescriptor<OwnedCharacterSkin>(
            predicate: #Predicate { $0.id == key }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func addOwnedSkin(
        characterID: String,
        skinID: String,
        in context: ModelContext
    ) {
        guard !ownsSkin(characterID: characterID, skinID: skinID, in: context)
        else {
            return
        }
        context.insert(
            OwnedCharacterSkin(characterID: characterID, skinID: skinID)
        )
        save(context)
    }

    static func setTeam(
        characterID: String,
        slotIndex: Int = 0,
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<TeamMemberRecord>(
            predicate: #Predicate { $0.slotIndex == slotIndex }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.characterID = characterID
        } else {
            context.insert(
                TeamMemberRecord(slotIndex: slotIndex, characterID: characterID)
            )
        }
        save(context)
    }

    static func isBattleCompleted(_ battleID: String, in context: ModelContext)
        -> Bool
    {
        let descriptor = FetchDescriptor<PlayerBattleProgress>(
            predicate: #Predicate { $0.battleID == battleID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func markBattleCompleted(
        _ battleID: String,
        in context: ModelContext
    ) {
        guard !isBattleCompleted(battleID, in: context) else { return }
        context.insert(PlayerBattleProgress(battleID: battleID))
        save(context)
    }

    static func recordBattleVictory(
        defeatedEnemyCount: Int,
        in context: ModelContext
    ) {
        incrementQuestCounter(
            battleVictoryCounterKey,
            by: 1,
            in: context,
            shouldSave: false
        )
        incrementQuestCounter(
            monsterKillCounterKey,
            by: max(0, defeatedEnemyCount),
            in: context,
            shouldSave: false
        )
        save(context)
    }

    static func hasSeenCutscene(_ cutsceneID: String, in context: ModelContext)
        -> Bool
    {
        let descriptor = FetchDescriptor<SeenCutsceneRecord>(
            predicate: #Predicate { $0.cutsceneID == cutsceneID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func markCutsceneSeen(_ cutsceneID: String, in context: ModelContext)
    {
        guard !hasSeenCutscene(cutsceneID, in: context) else { return }
        context.insert(SeenCutsceneRecord(cutsceneID: cutsceneID))
        save(context)
    }

    static func setDeckCard(
        cardID: String,
        slotIndex: Int,
        in context: ModelContext
    ) {
        let descriptor = FetchDescriptor<PlayerDeckCardSlot>(
            predicate: #Predicate { $0.slotIndex == slotIndex }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.cardID = cardID
        } else {
            context.insert(
                PlayerDeckCardSlot(slotIndex: slotIndex, cardID: cardID)
            )
        }
        save(context)
    }

    static func addOwnedCard(
        cardID: String,
        amount: Int = 1,
        in context: ModelContext
    ) {
        guard amount > 0 else { return }
        let descriptor = FetchDescriptor<OwnedAbilityCard>(
            predicate: #Predicate { $0.cardID == cardID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.count += amount
        } else {
            context.insert(OwnedAbilityCard(cardID: cardID, count: amount))
        }
        save(context)
    }

    static func progress(for characterID: String, in context: ModelContext)
        -> PlayerCharacterProgress?
    {
        let descriptor = FetchDescriptor<PlayerCharacterProgress>(
            predicate: #Predicate { $0.characterID == characterID }
        )
        return try? context.fetch(descriptor).first
    }

    static func addXP(
        _ amount: Int,
        to characterID: String,
        in context: ModelContext
    ) -> PlayerCharacterProgress {
        let existing = progress(for: characterID, in: context)
        let progress =
            existing ?? PlayerCharacterProgress(characterID: characterID)
        if existing == nil {
            context.insert(progress)
        }

        progress.xp += max(0, amount)
        progress.level = level(
            forCharacterXP: progress.xp,
            ascendedLevel: accountProgress(in: context).level
        )
        save(context)
        return progress
    }

    static func accountProgress(in context: ModelContext)
        -> PlayerAccountProgress
    {
        let descriptor = FetchDescriptor<PlayerAccountProgress>(
            predicate: #Predicate { $0.id == "ascended" }
        )
        if let progress = try? context.fetch(descriptor).first {
            return progress
        }

        let progress = PlayerAccountProgress()
        context.insert(progress)
        save(context)
        return progress
    }

    static func addAccountXP(_ amount: Int, in context: ModelContext)
        -> PlayerAccountProgress
    {
        let progress = accountProgress(in: context)
        progress.xp += max(0, amount)
        progress.level = level(forXP: progress.xp)
        save(context)
        return progress
    }

    static func summonCount(for bannerID: String, in context: ModelContext)
        -> Int
    {
        summonProgress(for: bannerID, in: context)?.summonCount ?? 0
    }

    static func shopPurchaseCount(for offerID: String, in context: ModelContext)
        -> Int
    {
        shopOfferProgress(for: offerID, in: context)?.purchaseCount ?? 0
    }

    static func claimGiftBox(
        _ gift: GiftBoxDefinition,
        in context: ModelContext
    ) -> Bool {
        guard !isGiftClaimed(gift.id, in: context) else { return false }
        add(gift.rewards, in: context)
        for characterReward in gift.characterRewards {
            addOwned(characterID: characterReward.characterID, in: context)
        }
        context.insert(PlayerClaimedGift(giftID: gift.id))
        save(context)
        return true
    }

    static func isGiftClaimed(_ giftID: String, in context: ModelContext)
        -> Bool
    {
        let descriptor = FetchDescriptor<PlayerClaimedGift>(
            predicate: #Predicate { $0.giftID == giftID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func dailyLoginGift(
        from rewards: [DailyLoginRewardDefinition],
        now: Date = .now,
        in context: ModelContext
    ) -> DailyLoginRewardState? {
        guard !rewards.isEmpty else { return nil }

        let progress = dailyLoginProgress(in: context)
        guard
            let nextIndex = nextDailyGiftIndex(
                progress: progress,
                rewards: rewards,
                now: now
            )
        else {
            return nil
        }

        return DailyLoginRewardState(
            reward: rewards[nextIndex],
            dayNumber: rewards[nextIndex].day
        )
    }

    @discardableResult
    static func claimDailyLoginGift(
        from rewards: [DailyLoginRewardDefinition],
        now: Date = .now,
        in context: ModelContext
    ) -> DailyLoginRewardState? {
        guard
            let availableGift = dailyLoginGift(
                from: rewards,
                now: now,
                in: context
            )
        else {
            return nil
        }

        add(availableGift.reward.rewards, in: context)

        let progress = dailyLoginProgress(in: context)
        let calendar = Calendar.current

        if let lastClaimedAt = progress.lastClaimedAt,
            isNextCalendarDay(
                after: lastClaimedAt,
                comparedTo: now,
                calendar: calendar
            )
        {
            progress.streakCount += 1
        } else {
            progress.streakCount = 1
        }

        progress.totalClaims += 1
        progress.lastClaimedAt = now
        save(context)

        return availableGift
    }

    @discardableResult
    static func incrementSummonCount(
        for bannerID: String,
        in context: ModelContext
    ) -> SummonBannerProgress {
        let existing = summonProgress(for: bannerID, in: context)
        let progress = existing ?? SummonBannerProgress(bannerID: bannerID)
        if existing == nil {
            context.insert(progress)
        }
        progress.summonCount += 1
        save(context)
        return progress
    }

    @discardableResult
    static func incrementShopPurchaseCount(
        for offerID: String,
        in context: ModelContext
    ) -> ShopOfferProgress {
        let existing = shopOfferProgress(for: offerID, in: context)
        let progress = existing ?? ShopOfferProgress(offerID: offerID)
        if existing == nil {
            context.insert(progress)
        }
        progress.purchaseCount += 1
        save(context)
        return progress
    }

    static func hasProcessedStoreTransaction(
        _ transactionID: String,
        in context: ModelContext
    ) -> Bool {
        let descriptor = FetchDescriptor<ProcessedStoreTransaction>(
            predicate: #Predicate { $0.transactionID == transactionID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func markStoreTransactionProcessed(
        _ transactionID: String,
        in context: ModelContext
    ) {
        guard !hasProcessedStoreTransaction(transactionID, in: context) else {
            return
        }
        context.insert(ProcessedStoreTransaction(transactionID: transactionID))
        save(context)
    }

    static func isQuestClaimed(_ questID: String, in context: ModelContext)
        -> Bool
    {
        let descriptor = FetchDescriptor<PlayerQuestClaim>(
            predicate: #Predicate { $0.questID == questID }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    static func questProgress(
        for objective: QuestObjectiveDefinition,
        in context: ModelContext
    ) -> Int {
        switch objective.type {
        case .ascendedLevel:
            return accountProgress(in: context).level
        case .battleVictories:
            return questCounterValue(for: battleVictoryCounterKey, in: context)
        case .monsterKills:
            return questCounterValue(for: monsterKillCounterKey, in: context)
        case .currencyCollect:
            return questCounterValue(
                for: currencyEarnedCounterKey(
                    for: objective.currency ?? "coins"
                ),
                in: context
            )
        }
    }

    static func canClaimQuest(
        _ quest: QuestDefinition,
        in context: ModelContext
    )
        -> Bool
    {
        guard !isQuestClaimed(quest.id, in: context) else { return false }
        guard accountProgress(in: context).level >= quest.requiredAscendedLevel
        else {
            return false
        }
        return questProgress(for: quest.objective, in: context)
            >= quest.objective.target
    }

    @discardableResult
    static func claimQuest(
        _ quest: QuestDefinition,
        selectedCharacterID: String? = nil,
        in context: ModelContext
    ) -> Bool {
        guard canClaimQuest(quest, in: context) else { return false }

        if !quest.choiceCharacterRewardIDs.isEmpty {
            guard let selectedCharacterID,
                quest.choiceCharacterRewardIDs.contains(selectedCharacterID)
            else {
                return false
            }
            addOwned(characterID: selectedCharacterID, in: context)
        }

        add(quest.rewards, in: context)

        for reward in quest.characterRewards {
            addOwned(characterID: reward.characterID, in: context)
        }

        context.insert(PlayerQuestClaim(questID: quest.id))
        save(context)
        return true
    }

    static func level(forCharacterXP xp: Int, ascendedLevel: Int) -> Int {
        var level = 1
        var remainingXP = max(0, xp)

        while remainingXP
            >= characterXPNeededForNextLevel(
                level,
                ascendedLevel: ascendedLevel
            )
        {
            remainingXP -= characterXPNeededForNextLevel(
                level,
                ascendedLevel: ascendedLevel
            )
            level += 1
        }

        return level
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        var remainingXP = max(0, xp)

        while remainingXP >= xpNeededForNextLevel(level) {
            remainingXP -= xpNeededForNextLevel(level)
            level += 1
        }

        return level
    }

    static func xpNeededForNextLevel(_ level: Int) -> Int {
        Int((100.0 * pow(1.35, Double(max(1, level) - 1))).rounded())
    }

    static func characterXPNeededForNextLevel(
        _ level: Int,
        ascendedLevel: Int
    ) -> Int {
        let baseXP = Double(xpNeededForNextLevel(level))
        let growth = loadBattleResourceConfiguration().progression
            .characterXPGrowthPerAscendedLevel
        let ascendedScale = pow(
            Double(growth),
            Double(max(0, ascendedLevel - 1))
        )
        return Int((baseXP * ascendedScale).rounded())
    }

    static func scaledCharacterStats(
        for character: CharacterStats,
        characterLevel: Int,
        ascendedLevel: Int
    ) -> CharacterStats {
        let progression = loadBattleResourceConfiguration().progression
        let characterHPScale = pow(
            progression.characterHPGrowthPerCharacterLevel,
            Double(max(0, characterLevel - 1))
        )
        let characterAttackScale = pow(
            progression.characterAttackGrowthPerCharacterLevel,
            Double(max(0, characterLevel - 1))
        )
        let ascendedHPScale = pow(
            progression.characterHPGrowthPerAscendedLevel,
            Double(max(0, ascendedLevel - 1))
        )
        let ascendedAttackScale = pow(
            progression.characterAttackGrowthPerAscendedLevel,
            Double(max(0, ascendedLevel - 1))
        )

        return CharacterStats(
            name: character.name,
            image: character.image,
            model: character.model,
            battleModel: character.battleModel,
            texture: character.texture,
            element: character.element,
            hp: character.hp * CGFloat(characterHPScale * ascendedHPScale),
            attack: character.attack
                * CGFloat(characterAttackScale * ascendedAttackScale)
        )
    }

    private static func summonProgress(
        for bannerID: String,
        in context: ModelContext
    ) -> SummonBannerProgress? {
        let descriptor = FetchDescriptor<SummonBannerProgress>(
            predicate: #Predicate { $0.bannerID == bannerID }
        )
        return try? context.fetch(descriptor).first
    }

    private static func shopOfferProgress(
        for offerID: String,
        in context: ModelContext
    ) -> ShopOfferProgress? {
        let descriptor = FetchDescriptor<ShopOfferProgress>(
            predicate: #Predicate { $0.offerID == offerID }
        )
        return try? context.fetch(descriptor).first
    }

    private static func dailyLoginProgress(in context: ModelContext)
        -> PlayerDailyLoginProgress
    {
        let descriptor = FetchDescriptor<PlayerDailyLoginProgress>(
            predicate: #Predicate { $0.id == "daily_login" }
        )
        if let progress = try? context.fetch(descriptor).first {
            return progress
        }

        let progress = PlayerDailyLoginProgress()
        context.insert(progress)
        save(context)
        return progress
    }

    private static func battleResourceState(
        configuration: BattleResourceResolvedConfiguration,
        in context: ModelContext,
        now: Date
    ) -> PlayerBattleResourceState {
        let descriptor = FetchDescriptor<PlayerBattleResourceState>(
            predicate: #Predicate { $0.id == "battle_resources" }
        )
        let state: PlayerBattleResourceState
        if let existing = try? context.fetch(descriptor).first {
            state = existing
        } else {
            state = PlayerBattleResourceState(
                currentEnergy: configuration.energy.maximum,
                availableCoinsLimit: configuration.coinLimit.maximum,
                availableCrystalsLimit: configuration.crystalLimit.maximum,
                lastUpdatedAt: now
            )
            context.insert(state)
            save(context)
        }

        regenerateBattleResourcesIfNeeded(
            state,
            configuration: configuration,
            in: context,
            now: now
        )
        return state
    }

    private static func regenerateBattleResourcesIfNeeded(
        _ state: PlayerBattleResourceState,
        configuration: BattleResourceResolvedConfiguration,
        in context: ModelContext,
        now: Date
    ) {
        let elapsedSeconds = now.timeIntervalSince(state.lastUpdatedAt)
        let elapsedMinutes = Int(elapsedSeconds / 60)
        guard elapsedMinutes > 0 else { return }

        state.currentEnergy = min(
            configuration.energy.maximum,
            state.currentEnergy
                + (elapsedMinutes * configuration.energy.regenerationPerMinute)
        )
        state.availableCoinsLimit = min(
            configuration.coinLimit.maximum,
            state.availableCoinsLimit
                + (elapsedMinutes
                    * configuration.coinLimit.regenerationPerMinute)
        )
        state.availableCrystalsLimit = min(
            configuration.crystalLimit.maximum,
            state.availableCrystalsLimit
                + (elapsedMinutes
                    * configuration.crystalLimit.regenerationPerMinute)
        )
        state.lastUpdatedAt = state.lastUpdatedAt.addingTimeInterval(
            TimeInterval(elapsedMinutes * 60)
        )
        save(context)
    }

    private static func questCounter(
        for key: String,
        in context: ModelContext
    ) -> PlayerQuestCounter {
        let descriptor = FetchDescriptor<PlayerQuestCounter>(
            predicate: #Predicate { $0.key == key }
        )
        if let counter = try? context.fetch(descriptor).first {
            return counter
        }

        let counter = PlayerQuestCounter(key: key)
        context.insert(counter)
        save(context)
        return counter
    }

    private static func questCounterValue(
        for key: String,
        in context: ModelContext
    )
        -> Int
    {
        let descriptor = FetchDescriptor<PlayerQuestCounter>(
            predicate: #Predicate { $0.key == key }
        )
        return (try? context.fetch(descriptor).first?.value) ?? 0
    }

    private static func incrementQuestCounter(
        _ key: String,
        by amount: Int,
        in context: ModelContext,
        shouldSave: Bool
    ) {
        guard amount > 0 else { return }
        let counter = questCounter(for: key, in: context)
        counter.value += amount
        if shouldSave {
            save(context)
        }
    }

    private static func currencyEarnedCounterKey(for currency: String) -> String
    {
        "currency_earned_\(currency)"
    }

    private static func nextDailyGiftIndex(
        progress: PlayerDailyLoginProgress,
        rewards: [DailyLoginRewardDefinition],
        now: Date
    ) -> Int? {
        let calendar = Calendar.current

        guard let lastClaimedAt = progress.lastClaimedAt else {
            return 0
        }

        if calendar.isDate(lastClaimedAt, inSameDayAs: now) {
            return nil
        }

        if isNextCalendarDay(
            after: lastClaimedAt,
            comparedTo: now,
            calendar: calendar
        ) {
            return progress.streakCount % rewards.count
        }

        return 0
    }

    private static func isNextCalendarDay(
        after previousDate: Date,
        comparedTo currentDate: Date,
        calendar: Calendar
    ) -> Bool {
        let previousStart = calendar.startOfDay(for: previousDate)
        let currentStart = calendar.startOfDay(for: currentDate)
        let dayDifference =
            calendar.dateComponents(
                [.day],
                from: previousStart,
                to: currentStart
            ).day ?? 0
        return dayDifference == 1
    }

    private static func save(_ context: ModelContext) {
        try? context.save()
    }
}
