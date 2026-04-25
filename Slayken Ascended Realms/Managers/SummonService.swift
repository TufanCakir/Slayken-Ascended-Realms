//
//  SummonService.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum SummonDrop: Equatable {
    case character(SummonCharacter)
    case card(AbilityCardDefinition)
}

enum SummonService {
    static func summon(
        from banner: SummonBanner,
        characters: [SummonCharacter],
        cards: [AbilityCardDefinition],
        summonNumber: Int
    ) -> SummonDrop? {
        let charactersByID = Dictionary(
            uniqueKeysWithValues: characters.map { ($0.id, $0) }
        )
        let cardsByID = Dictionary(
            uniqueKeysWithValues: cards.map { ($0.id, $0) }
        )

        let weightedPool = weightedDrops(
            for: banner.pool,
            charactersByID: charactersByID,
            cardsByID: cardsByID
        )

        if let guarantee = banner.guarantee,
            guarantee.appliesOnSummon == summonNumber
        {
            let guaranteedPool = weightedPool.filter {
                matchesGuarantee($0.0, guarantee: guarantee)
            }
            if let guaranteedDrop = roll(from: guaranteedPool) {
                return guaranteedDrop
            }
        }

        return roll(from: weightedPool)
    }

    private static func weightedDrops(
        for pool: [SummonPoolEntry],
        charactersByID: [String: SummonCharacter],
        cardsByID: [String: AbilityCardDefinition]
    ) -> [(SummonDrop, Double)] {
        pool.compactMap {
            entry -> (SummonDrop, Double)? in
            guard entry.weight > 0 else { return nil }
            if let characterID = entry.characterID,
                let character = charactersByID[characterID]
            {
                return (.character(character), entry.weight)
            }
            if let cardID = entry.cardID, let card = cardsByID[cardID] {
                return (.card(card), entry.weight)
            }
            return nil
        }
    }

    private static func matchesGuarantee(
        _ drop: SummonDrop,
        guarantee: SummonGuarantee
    ) -> Bool {
        switch drop {
        case .character(let character):
            guard guarantee.dropType != "card" else { return false }
            return guarantee.rarity.map { character.rarity >= $0 } ?? true
        case .card(let card):
            guard guarantee.dropType != "character" else { return false }
            return guarantee.rarity.map { card.resolvedRarity >= $0 } ?? true
        }
    }

    private static func roll(from weightedPool: [(SummonDrop, Double)])
        -> SummonDrop?
    {
        let totalWeight = weightedPool.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return nil }

        var roll = Double.random(in: 0..<totalWeight)
        for (drop, weight) in weightedPool {
            roll -= weight
            if roll <= 0 {
                return drop
            }
        }

        return weightedPool.last?.0
    }
}
