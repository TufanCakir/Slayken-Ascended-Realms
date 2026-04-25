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
        }
        save(context)
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

    static func addOwnedCard(cardID: String, in context: ModelContext) {
        let descriptor = FetchDescriptor<OwnedAbilityCard>(
            predicate: #Predicate { $0.cardID == cardID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.count += 1
        } else {
            context.insert(OwnedAbilityCard(cardID: cardID))
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
        progress.level = level(forXP: progress.xp)
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

    static func isGiftClaimed(_ giftID: String, in context: ModelContext) -> Bool {
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

    private static func summonProgress(
        for bannerID: String,
        in context: ModelContext
    ) -> SummonBannerProgress? {
        let descriptor = FetchDescriptor<SummonBannerProgress>(
            predicate: #Predicate { $0.bannerID == bannerID }
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
