//
//  SummonService.swift
//  Slayken Ascended Realms
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
        cards: [AbilityCardDefinition]
    ) -> SummonDrop?
    {
        let charactersByID = Dictionary(
            uniqueKeysWithValues: characters.map { ($0.id, $0) }
        )
        let cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })

        let weightedPool = banner.pool.compactMap { entry -> (SummonDrop, Double)? in
            guard entry.weight > 0 else { return nil }
            if let characterID = entry.characterID, let character = charactersByID[characterID] {
                return (.character(character), entry.weight)
            }
            if let cardID = entry.cardID, let card = cardsByID[cardID] {
                return (.card(card), entry.weight)
            }
            return nil
        }

        let totalWeight = weightedPool.reduce(0) { $0 + $1.1 }
        guard totalWeight > 0 else { return nil }

        var roll = Double.random(in: 0..<totalWeight)
        for (character, weight) in weightedPool {
            roll -= weight
            if roll <= 0 {
                return character
            }
        }

        return weightedPool.last?.0
    }
}
