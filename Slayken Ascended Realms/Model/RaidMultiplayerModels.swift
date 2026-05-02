//
//  RaidMultiplayerModels.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import CoreGraphics
import Foundation

enum RaidParticipantConnectionState: String, Codable, Equatable {
    case idle
    case matchmaking
    case connected
    case disconnected
    case inRaid
}

enum RaidRoleType: String, Codable, Equatable {
    case tank
    case healer
    case damageDealer
    case supporter
}

struct RaidRoleDefinition: Codable, Equatable, Identifiable {
    let id: String
    let role: RaidRoleType
    let displayName: String
    let summary: String
    let preferredCount: Int
    let attackBonusPercent: Int
    let maxHPBonusPercent: Int
    let healPower: Int
    let shieldValue: Int
    let bossDamageReductionPercent: Int
    let tauntWeight: Int
}

struct RaidPartyCharacterDefinition: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let model: String
    let texture: String?
    let previewImage: String?
}

struct RaidCoopCurrencyReward: Codable, Equatable, Identifiable {
    let code: String
    let name: String
    let icon: String
    let assetIcon: String?
    let amount: Int
    let sortOrder: Int

    var id: String { code }

    var asCurrencyDefinition: CurrencyDefinition {
        CurrencyDefinition(
            code: code,
            name: name,
            icon: icon,
            assetIcon: assetIcon,
            sortOrder: sortOrder
        )
    }

    var asCurrencyAmount: CurrencyAmount {
        CurrencyAmount(currency: code, amount: amount)
    }
}

struct RaidBossDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let maxHP: Int
    let attack: Int
    let recommendedPartySize: Int
    let summary: String
    let model: String
    let texture: String?
    let element: String
    let groundTexture: String
    let skyboxTexture: String
    let difficulty: Int
    let recommendedCharacterLevel: Int
    let xpReward: Int
    let rewards: [CurrencyAmount]
    let coopCurrencies: [RaidCoopCurrencyReward]?
    let cardRewards: [GlobeBattle.CardReward]
    let raidRoles: [RaidRoleDefinition]
    let partyCharacters: [RaidPartyCharacterDefinition]?
    let startCountdownSeconds: Int?

    var resolvedPartyCharacters: [RaidPartyCharacterDefinition] {
        partyCharacters ?? []
    }

    var resolvedStartCountdownSeconds: Int {
        max(0, startCountdownSeconds ?? 5)
    }

    var resolvedCoopCurrencies: [RaidCoopCurrencyReward] {
        coopCurrencies ?? []
    }

    var resolvedRewards: [CurrencyAmount] {
        rewards + resolvedCoopCurrencies.map(\.asCurrencyAmount)
    }

    var rewardCurrencyDefinitions: [CurrencyDefinition] {
        resolvedCoopCurrencies.map(\.asCurrencyDefinition)
    }

    var battleCharacter: CharacterStats {
        CharacterStats(
            name: name,
            image: "sar_dragon",
            model: model,
            battleModel: model,
            texture: texture,
            element: element,
            hp: CGFloat(maxHP),
            attack: CGFloat(attack)
        )
    }

}

func loadRaidBossDefinitions() -> [RaidBossDefinition] {
    JSONResourceLoader.loadArray(
        RaidBossDefinition.self,
        resource: "raid_bosses"
    )
}

func loadRaidCurrencyDefinitions() -> [CurrencyDefinition] {
    var definitionsByCode = [String: CurrencyDefinition]()

    for boss in loadRaidBossDefinitions() {
        for definition in boss.rewardCurrencyDefinitions {
            definitionsByCode[definition.code] = definition
        }
    }

    return definitionsByCode.values.sorted { $0.sortOrder < $1.sortOrder }
}

struct RaidParticipant: Identifiable, Codable, Equatable {
    let id: String
    var displayName: String
    var isLocalPlayer: Bool
    var isHost: Bool
    var isBot: Bool
    var role: RaidRoleType?
    var roleName: String?
    var roleSummary: String?
    var characterName: String?
    var characterModel: String?
    var characterTexture: String?
    var characterPreviewImage: String?
    var isReady: Bool
    var connectionState: RaidParticipantConnectionState
    var currentHP: Int
    var maxHP: Int

    var healthProgress: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }
}

struct RaidLobbyState: Identifiable, Codable, Equatable {
    let id: String
    let boss: RaidBossDefinition
    var participants: [RaidParticipant]
    let minimumPlayers: Int
    let maximumPlayers: Int
    var statusText: String

    var readyPlayers: Int {
        participants.filter(\.isReady).count
    }

    var connectedPlayers: Int {
        participants.filter { $0.connectionState != .disconnected }.count
    }

    var canStartRaid: Bool {
        connectedPlayers >= minimumPlayers && readyPlayers >= minimumPlayers
    }

    var missingPartySlots: Int {
        max(0, maximumPlayers - participants.count)
    }
}

struct ActiveRaidSession: Identifiable, Codable, Equatable {
    let id: String
    let boss: RaidBossDefinition
    var participants: [RaidParticipant]
    var bossHP: Int
    var combatLog: [String]
    var bossTargetParticipantID: String?
    var bossTargetParticipantName: String?

    var bossHealthProgress: Double {
        guard boss.maxHP > 0 else { return 0 }
        return Double(bossHP) / Double(boss.maxHP)
    }

    var battleConfiguration: RaidBattleConfiguration {
        let localParticipant = participants.first(where: \.isLocalPlayer)
        return RaidBattleConfiguration(
            sessionID: id,
            boss: boss.battleCharacter,
            groundTexture: boss.groundTexture,
            skyboxTexture: boss.skyboxTexture,
            difficulty: boss.difficulty,
            xpReward: boss.xpReward,
            rewards: boss.resolvedRewards,
            rewardCurrencyDefinitions: boss.rewardCurrencyDefinitions,
            cardRewards: boss.cardRewards,
            startingBossHP: bossHP,
            localParticipantID: localParticipant?.id ?? "",
            localParticipantHP: localParticipant?.currentHP ?? 1,
            localParticipantMaxHP: localParticipant?.maxHP ?? 1,
            bossTargetParticipantID: bossTargetParticipantID
        )
    }
}

struct RaidBattleConfiguration: Equatable {
    let sessionID: String
    let boss: CharacterStats
    let groundTexture: String
    let skyboxTexture: String
    let difficulty: Int
    let xpReward: Int
    let rewards: [CurrencyAmount]
    let rewardCurrencyDefinitions: [CurrencyDefinition]
    let cardRewards: [GlobeBattle.CardReward]
    let startingBossHP: Int
    let localParticipantID: String
    let localParticipantHP: Int
    let localParticipantMaxHP: Int
    let bossTargetParticipantID: String?
}

struct RaidResolvedPlayerAction: Equatable, Identifiable {
    let id: String
    let sessionID: String
    let actorID: String
    let actorName: String
    let actionName: String
    let damage: Int
    let resultingBossHP: Int
    let victory: Bool
}

struct RaidResolvedBossAttack: Equatable, Identifiable {
    let id: String
    let sessionID: String
    let bossName: String
    let targetParticipantID: String
    let targetParticipantName: String
    let damage: Int
    let resultingHP: Int
    let defeat: Bool
}

struct RaidMessage: Codable, Equatable {
    enum Kind: String, Codable, Equatable {
        case readyState
        case bossAttack
        case playerAction
        case raidSnapshot
        case stateSync
        case raidStarted
        case raidEnded
    }

    let kind: Kind
    let senderID: String
    let timestamp: Date
    let payload: [String: String]
}

struct RaidResumeSnapshot: Codable, Equatable {
    let lobbyState: RaidLobbyState?
    let activeRaid: ActiveRaidSession?
}
