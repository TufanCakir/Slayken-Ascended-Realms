//
//  PlayerCurrencyBalance.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
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

    init(
        characterID: String,
        selectedSkinID: String? = nil,
        acquiredAt: Date = .now
    ) {
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

@Model
final class PlayerDeckCardSlot {
    @Attribute(.unique) var slotIndex: Int
    var cardID: String

    init(slotIndex: Int, cardID: String) {
        self.slotIndex = slotIndex
        self.cardID = cardID
    }
}

@Model
final class OwnedAbilityCard {
    @Attribute(.unique) var cardID: String
    var count: Int
    var acquiredAt: Date

    init(cardID: String, count: Int = 1, acquiredAt: Date = .now) {
        self.cardID = cardID
        self.count = count
        self.acquiredAt = acquiredAt
    }
}

@Model
final class PlayerCharacterProgress {
    @Attribute(.unique) var characterID: String
    var level: Int
    var xp: Int

    init(characterID: String, level: Int = 1, xp: Int = 0) {
        self.characterID = characterID
        self.level = level
        self.xp = xp
    }
}

@Model
final class PlayerAccountProgress {
    @Attribute(.unique) var id: String
    var level: Int
    var xp: Int

    init(id: String = "ascended", level: Int = 1, xp: Int = 0) {
        self.id = id
        self.level = level
        self.xp = xp
    }
}

@Model
final class SeenCutsceneRecord {
    @Attribute(.unique) var cutsceneID: String
    var seenAt: Date

    init(cutsceneID: String, seenAt: Date = .now) {
        self.cutsceneID = cutsceneID
        self.seenAt = seenAt
    }
}

@Model
final class SummonBannerProgress {
    @Attribute(.unique) var bannerID: String
    var summonCount: Int

    init(bannerID: String, summonCount: Int = 0) {
        self.bannerID = bannerID
        self.summonCount = summonCount
    }
}

@Model
final class PlayerDailyLoginProgress {
    @Attribute(.unique) var id: String
    var lastClaimedAt: Date?
    var streakCount: Int
    var totalClaims: Int

    init(
        id: String = "daily_login",
        lastClaimedAt: Date? = nil,
        streakCount: Int = 0,
        totalClaims: Int = 0
    ) {
        self.id = id
        self.lastClaimedAt = lastClaimedAt
        self.streakCount = streakCount
        self.totalClaims = totalClaims
    }
}
