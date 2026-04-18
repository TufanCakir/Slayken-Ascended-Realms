//
//  PlayerInventoryStore.swift
//  Slayken Ascended Realms
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

    private static func save(_ context: ModelContext) {
        try? context.save()
    }
}
