//
//  SummonService.swift
//  Slayken Ascended Realms
//

import Foundation

enum SummonService {
    static func summon(from banner: SummonBanner, characters: [SummonCharacter]) -> SummonCharacter? {
        let poolByID = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0) })
        let weightedPool = banner.pool.compactMap { entry -> (SummonCharacter, Double)? in
            guard let character = poolByID[entry.characterID], entry.weight > 0 else { return nil }
            return (character, entry.weight)
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
