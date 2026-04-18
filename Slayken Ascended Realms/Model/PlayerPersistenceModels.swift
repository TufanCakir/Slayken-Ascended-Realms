//
//  PlayerPersistenceModels.swift
//  Slayken Ascended Realms
//

import Foundation
import SwiftData

@Model
final class PlayerCurrencyBalance {
    @Attribute(.unique) var code: String
    var amount: Int

    init(code: String, amount: Int = 0) {
        self.code = code
        self.amount = amount
    }
}

@Model
final class OwnedSummonCharacter {
    @Attribute(.unique) var characterID: String
    var selectedSkinID: String?
    var acquiredAt: Date

    init(characterID: String, selectedSkinID: String? = nil, acquiredAt: Date = .now) {
        self.characterID = characterID
        self.selectedSkinID = selectedSkinID
        self.acquiredAt = acquiredAt
    }
}

@Model
final class TeamMemberRecord {
    @Attribute(.unique) var slotIndex: Int
    var characterID: String

    init(slotIndex: Int, characterID: String) {
        self.slotIndex = slotIndex
        self.characterID = characterID
    }
}

@Model
final class PlayerBattleProgress {
    @Attribute(.unique) var battleID: String
    var completedAt: Date

    init(battleID: String, completedAt: Date = .now) {
        self.battleID = battleID
        self.completedAt = completedAt
    }
}
