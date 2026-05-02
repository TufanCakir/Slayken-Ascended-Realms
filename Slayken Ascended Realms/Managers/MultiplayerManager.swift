//
//  MultiplayerManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import Foundation
import GameKit
import SwiftUI
import UIKit

@MainActor
final class MultiplayerManager: NSObject, ObservableObject {

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isMatchmaking = false
    @Published private(set) var activeMatch: GKMatch?
    @Published private(set) var lobbyState: RaidLobbyState?
    @Published private(set) var activeRaid: ActiveRaidSession?
    @Published private(set) var latestResolvedRaidAction:
        RaidResolvedPlayerAction?
    @Published private(set) var latestResolvedRaidBossAttack:
        RaidResolvedBossAttack?
    @Published private(set) var localPlayerName = "Adventurer"
    @Published private(set) var raidCountdownRemaining: Int?
    @Published var lastErrorMessage: String?

    private var raidBotTask: Task<Void, Never>?
    private var raidCountdownTask: Task<Void, Never>?
    private var pendingBossAttackSessionID: String?

    var availableRaidBosses: [RaidBossDefinition] {
        loadRaidBossDefinitions()
    }

    private var currentSelectedBoss: RaidBossDefinition? {
        lobbyState?.boss ?? availableRaidBosses.first
    }

    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = {
            [weak self] viewController, error in
            guard let self else { return }

            if let error {
                self.lastErrorMessage = error.localizedDescription
            }

            if let viewController {
                self.present(viewController)
                return
            }

            self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            self.localPlayerName =
                GKLocalPlayer.local.displayName.isEmpty
                ? "Adventurer" : GKLocalPlayer.local.displayName

            if self.isAuthenticated {
                GKLocalPlayer.local.register(self)
                self.ensureLocalLobbyState()
            }
        }
    }

    func ensureLocalLobbyState() {
        guard lobbyState == nil else { return }
        guard let boss = currentSelectedBoss else {
            lastErrorMessage = "Keine Raid-Bossdaten geladen."
            return
        }
        lobbyState = makeOfflineLobbyState(
            statusText: "Waehle einen Coop-Raidboss aus.",
            boss: boss
        )
    }

    func startRaidMatchmaking() {
        guard let selectedBoss = currentSelectedBoss else {
            lastErrorMessage = "Keine Raid-Bossdaten geladen."
            return
        }

        guard GKLocalPlayer.local.isAuthenticated else {
            lastErrorMessage = "Bitte zuerst bei Game Center anmelden."
            authenticatePlayer()
            return
        }

        guard !GKLocalPlayer.local.isMultiplayerGamingRestricted else {
            lastErrorMessage =
                "Multiplayer ist fuer diesen Account eingeschraenkt."
            return
        }

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 4

        guard
            let viewController = GKMatchmakerViewController(
                matchRequest: request
            )
        else {
            lastErrorMessage = "Matchmaking konnte nicht gestartet werden."
            return
        }

        viewController.matchmakerDelegate = self
        viewController.canStartWithMinimumPlayers = true
        isMatchmaking = true
        lobbyState = makeOfflineLobbyState(
            statusText: "Suche weitere Raid-Spieler ...",
            boss: selectedBoss
        )
        present(viewController)
    }

    func leaveLobby() {
        GKMatchmaker.shared().cancel()
        activeMatch?.disconnect()
        activeMatch?.delegate = nil
        activeMatch = nil
        activeRaid = nil
        isMatchmaking = false
        if let selectedBoss = currentSelectedBoss {
            lobbyState = makeOfflineLobbyState(
                statusText: "Raid-Lobby geschlossen",
                boss: selectedBoss
            )
        } else {
            lobbyState = nil
            lastErrorMessage = "Keine Raid-Bossdaten geladen."
        }
    }

    func selectRaidBoss(_ boss: RaidBossDefinition) {
        ensureLocalLobbyState()

        let previousParticipants = lobbyState?.participants ?? []
        let keptParticipants = previousParticipants.filter {
            $0.isLocalPlayer || !$0.isBot
        }
        let localParticipant =
            keptParticipants.first(where: \.isLocalPlayer)
            ?? RaidParticipant(
                id: localPlayerID,
                displayName: localPlayerName,
                isLocalPlayer: true,
                isHost: true,
                isBot: false,
                role: nil,
                roleName: nil,
                roleSummary: nil,
                characterName: nil,
                characterModel: nil,
                characterTexture: nil,
                characterPreviewImage: nil,
                isReady: false,
                connectionState: isAuthenticated ? .idle : .disconnected,
                currentHP: 1000,
                maxHP: 1000
            )

        let selectedState = RaidLobbyState(
            id: lobbyState?.id ?? UUID().uuidString,
            boss: boss,
            participants: [localParticipant],
            minimumPlayers: 2,
            maximumPlayers: 4,
            statusText:
                "Boss ausgewaehlt. Stelle jetzt deine Raid-Gruppe zusammen."
        )

        lobbyState = assignPartyCharacters(in: selectedState)
        lastErrorMessage = nil
    }

    func toggleReadyState() {
        guard var lobbyState else { return }
        guard
            let index = lobbyState.participants.firstIndex(
                where: \.isLocalPlayer
            )
        else {
            return
        }

        lobbyState.participants[index].isReady.toggle()
        lobbyState.statusText =
            lobbyState.participants[index].isReady
            ? "Du bist bereit. Warte auf die Gruppe."
            : "Nicht bereit. Passe dein Team noch an."
        self.lobbyState = lobbyState

        send(
            message: .init(
                kind: .readyState,
                senderID: lobbyState.participants[index].id,
                timestamp: .now,
                payload: [
                    "ready": lobbyState.participants[index].isReady
                        ? "true" : "false"
                ]
            )
        )
    }

    func startRaidIfPossible() {
        guard let lobbyState, lobbyState.canStartRaid else {
            lastErrorMessage =
                "Mindestens 2 verbundene und bereite Spieler werden benoetigt."
            return
        }

        startRaid(using: lobbyState)
    }

    func startSoloRaidWithBots() {
        ensureLocalLobbyState()
        guard var lobbyState else { return }
        guard
            let localIndex = lobbyState.participants.firstIndex(
                where: \.isLocalPlayer
            )
        else {
            return
        }

        lobbyState.participants = lobbyState.participants.filter {
            participant in
            participant.isLocalPlayer || !participant.isBot
        }
        lobbyState.participants[localIndex].isReady = true
        lobbyState.participants[localIndex].connectionState = .connected

        let desiredPartySize = min(
            lobbyState.maximumPlayers,
            max(lobbyState.minimumPlayers, lobbyState.boss.recommendedPartySize)
        )
        let missingSlots = max(
            0,
            desiredPartySize - lobbyState.participants.count
        )
        lobbyState.participants.append(
            contentsOf: makeBotParticipants(
                count: missingSlots,
                boss: lobbyState.boss
            )
        )
        lobbyState.statusText = "Solo-Raid mit Bots bereit."
        lobbyState = assignPartyCharacters(in: lobbyState)
        self.lobbyState = lobbyState

        startRaid(using: lobbyState)
    }

    private func startRaid(using lobbyState: RaidLobbyState) {
        raidBotTask?.cancel()
        raidCountdownTask?.cancel()

        let participantMaxHP = 1000
        let session = ActiveRaidSession(
            id: lobbyState.id,
            boss: lobbyState.boss,
            participants: lobbyState.participants.map {
                var participant = $0
                participant.connectionState = .inRaid
                let resolvedHP = resolvedParticipantMaxHP(
                    baseHP: participantMaxHP,
                    role: participant.role,
                    boss: lobbyState.boss
                )
                participant.currentHP = resolvedHP
                participant.maxHP = resolvedHP
                return participant
            },
            bossHP: lobbyState.boss.maxHP,
            combatLog: ["Raid gegen \(lobbyState.boss.name) gestartet."],
            bossTargetParticipantID: nil,
            bossTargetParticipantName: nil
        )

        activeRaid = session
        latestResolvedRaidAction = nil
        latestResolvedRaidBossAttack = nil
        pendingBossAttackSessionID = nil
        self.lobbyState?.statusText = "Raid aktiv"
        startRaidCountdown(
            seconds: lobbyState.boss.resolvedStartCountdownSeconds
        )
        startRaidBotLoopIfNeeded()

        send(
            message: .init(
                kind: .raidStarted,
                senderID: localPlayerID,
                timestamp: .now,
                payload: [
                    "bossID": lobbyState.boss.id,
                    "countdown":
                        "\(lobbyState.boss.resolvedStartCountdownSeconds)",
                ]
            )
        )
    }

    func submitRaidPlayerAction(actionName: String, proposedDamage: Int) {
        guard activeRaid != nil else { return }
        guard raidCountdownRemaining == nil else { return }
        let sanitizedDamage = max(1, proposedDamage)

        if isLocalRaidHost {
            resolveRaidPlayerAction(
                actorID: localPlayerID,
                actorName: localPlayerName,
                actionName: actionName,
                damage: sanitizedDamage,
                broadcastUpdate: true
            )
            return
        }

        send(
            message: .init(
                kind: .playerAction,
                senderID: localPlayerID,
                timestamp: .now,
                payload: [
                    "action": actionName,
                    "damage": "\(sanitizedDamage)",
                ]
            )
        )
    }

    func performLocalAttack() {
        submitRaidPlayerAction(
            actionName: "Basisangriff",
            proposedDamage: Int.random(in: 180...420)
        )
    }

    func syncRaidBossHP(_ bossHP: Int) {
        guard var activeRaid else { return }
        activeRaid.bossHP = max(0, bossHP)
        self.activeRaid = activeRaid
    }

    func syncRaidParticipantHP(participantID: String, hp: Int) {
        guard var activeRaid else { return }
        guard
            let index = activeRaid.participants.firstIndex(where: {
                $0.id == participantID
            })
        else {
            return
        }

        activeRaid.participants[index].currentHP = max(
            0,
            min(hp, activeRaid.participants[index].maxHP)
        )
        self.activeRaid = activeRaid
    }

    func appendRaidCombatLog(_ entry: String) {
        guard var activeRaid else { return }
        activeRaid.combatLog.insert(entry, at: 0)
        self.activeRaid = activeRaid
    }

    func setRaidOutcome(victory: Bool) {
        guard activeRaid != nil else { return }
        raidBotTask?.cancel()
        raidBotTask = nil
        lobbyState?.statusText =
            victory ? "Raidboss besiegt" : "Raid fehlgeschlagen"
        let outcomeEntry =
            victory
            ? "Der Raidboss wurde besiegt."
            : "Die Gruppe wurde im Raid besiegt."
        if activeRaid?.combatLog.first != outcomeEntry {
            appendRaidCombatLog(outcomeEntry)
        }
    }

    func endRaid() {
        raidBotTask?.cancel()
        raidBotTask = nil
        raidCountdownTask?.cancel()
        raidCountdownTask = nil
        raidCountdownRemaining = nil
        pendingBossAttackSessionID = nil
        activeRaid = nil
        latestResolvedRaidAction = nil
        latestResolvedRaidBossAttack = nil
        if lobbyState == nil {
            if let selectedBoss = currentSelectedBoss {
                lobbyState = makeOfflineLobbyState(
                    statusText: "Bereit fuer den naechsten Raid",
                    boss: selectedBoss
                )
            } else {
                lastErrorMessage = "Keine Raid-Bossdaten geladen."
            }
        } else {
            lobbyState?.statusText = "Raid beendet"
        }
    }

    func restartRaidWithFullHP() {
        guard activeRaid != nil else { return }
        guard let lobbyState, lobbyState.canStartRaid else {
            lastErrorMessage =
                "Der Raid kann aktuell nicht neu gestartet werden."
            return
        }

        startRaid(using: lobbyState)
    }

    private var localPlayerID: String {
        if GKLocalPlayer.local.isAuthenticated {
            return GKLocalPlayer.local.gamePlayerID
        }
        return UUID().uuidString
    }

    var isLocalRaidHost: Bool {
        lobbyState?.participants.first(where: \.isLocalPlayer)?.isHost ?? true
    }

    private func makeOfflineLobbyState(
        statusText: String,
        boss: RaidBossDefinition
    ) -> RaidLobbyState {
        let defaultHP = 1000
        return RaidLobbyState(
            id: UUID().uuidString,
            boss: boss,
            participants: [
                RaidParticipant(
                    id: localPlayerID,
                    displayName: localPlayerName,
                    isLocalPlayer: true,
                    isHost: true,
                    isBot: false,
                    role: nil,
                    roleName: nil,
                    roleSummary: nil,
                    characterName: nil,
                    characterModel: nil,
                    characterTexture: nil,
                    characterPreviewImage: nil,
                    isReady: false,
                    connectionState: isAuthenticated ? .idle : .disconnected,
                    currentHP: defaultHP,
                    maxHP: defaultHP
                )
            ],
            minimumPlayers: 2,
            maximumPlayers: 4,
            statusText: statusText
        )
    }

    private func syncLobbyParticipants(match: GKMatch, statusText: String) {
        guard let selectedBoss = currentSelectedBoss else {
            lastErrorMessage = "Keine Raid-Bossdaten geladen."
            lobbyState = nil
            return
        }

        let previousParticipants =
            activeRaid?.participants ?? lobbyState?.participants ?? []

        func mergedParticipant(
            id: String,
            displayName: String,
            isHost: Bool,
            connectionState: RaidParticipantConnectionState
        ) -> RaidParticipant {
            let previous = previousParticipants.first(where: { $0.id == id })
            return RaidParticipant(
                id: id,
                displayName: displayName,
                isLocalPlayer: id == localPlayerID,
                isHost: previous?.isHost ?? isHost,
                isBot: previous?.isBot ?? false,
                role: previous?.role,
                roleName: previous?.roleName,
                roleSummary: previous?.roleSummary,
                characterName: previous?.characterName,
                characterModel: previous?.characterModel,
                characterTexture: previous?.characterTexture,
                characterPreviewImage: previous?.characterPreviewImage,
                isReady: previous?.isReady ?? false,
                connectionState: connectionState,
                currentHP: previous?.currentHP ?? 1000,
                maxHP: previous?.maxHP ?? 1000
            )
        }

        var participants = [
            mergedParticipant(
                id: localPlayerID,
                displayName: localPlayerName,
                isHost: true,
                connectionState: .connected
            )
        ]

        participants.append(
            contentsOf: match.players.map { player in
                mergedParticipant(
                    id: player.gamePlayerID,
                    displayName: player.displayName,
                    isHost: false,
                    connectionState: .connected
                )
            }
        )

        let state = RaidLobbyState(
            id: lobbyState?.id ?? UUID().uuidString,
            boss: lobbyState?.boss ?? selectedBoss,
            participants: participants,
            minimumPlayers: 2,
            maximumPlayers: 4,
            statusText: statusText
        )
        lobbyState = assignPartyCharacters(in: state)
    }

    private func send(message: RaidMessage) {
        guard let activeMatch else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }

        do {
            try activeMatch.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func send(message: RaidMessage, to players: [GKPlayer]) {
        guard let activeMatch else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }

        do {
            try activeMatch.send(data, to: players, dataMode: .reliable)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func sendRaidSnapshot(to players: [GKPlayer]) {
        guard !players.isEmpty else { return }
        let snapshot = RaidResumeSnapshot(
            lobbyState: lobbyState,
            activeRaid: activeRaid
        )
        guard let snapshotData = try? JSONEncoder().encode(snapshot) else {
            return
        }

        let message = RaidMessage(
            kind: .raidSnapshot,
            senderID: localPlayerID,
            timestamp: .now,
            payload: [
                "snapshot": snapshotData.base64EncodedString()
            ]
        )
        send(message: message, to: players)
    }

    private func normalizeParticipants(_ participants: [RaidParticipant])
        -> [RaidParticipant]
    {
        participants.map { participant in
            var normalized = participant
            normalized.isLocalPlayer = participant.id == localPlayerID
            return normalized
        }
    }

    private func makeBotParticipants(
        count: Int,
        boss: RaidBossDefinition
    ) -> [RaidParticipant] {

        guard count > 0 else { return [] }

        let botNames = [
            "Aegis Bot",
            "Blaze Bot",
            "Crystal Bot",
            "Void Bot",
            "Storm Bot",
            "Moon Bot",
        ]

        let roleRotation = expandedBotRoleRotation(for: boss)
        let partyCharacters = boss.resolvedPartyCharacters

        return (0..<count).map { index in

            let roleDefinition =
                roleRotation.isEmpty
                ? nil
                : roleRotation[index % roleRotation.count]

            let character =
                partyCharacters.isEmpty
                ? nil
                : partyCharacters[index % partyCharacters.count]

            return RaidParticipant(
                id: "bot-\(UUID().uuidString)",
                displayName: character?.displayName
                    ?? botNames[index % botNames.count],
                isLocalPlayer: false,
                isHost: false,
                isBot: true,

                role: roleDefinition?.role,
                roleName: roleDefinition?.displayName,
                roleSummary: roleDefinition?.summary,

                characterName: character?.displayName,
                characterModel: character?.model,
                characterTexture: character?.texture,
                characterPreviewImage: character?.previewImage,

                isReady: true,
                connectionState: .connected,
                currentHP: 1000,
                maxHP: 1000
            )
        }
    }

    private func startRaidBotLoopIfNeeded() {
        raidBotTask?.cancel()
        guard isLocalRaidHost else { return }
        guard let activeRaid else { return }
        guard activeRaid.participants.contains(where: { $0.isBot }) else {
            return
        }

        let sessionID = activeRaid.id
        raidBotTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                if self.raidCountdownRemaining != nil {
                    try? await Task.sleep(for: .milliseconds(250))
                    continue
                }
                try? await Task.sleep(
                    for: .milliseconds(Int.random(in: 1400...2200))
                )
                guard !Task.isCancelled else { return }
                guard let activeRaid = self.activeRaid,
                    activeRaid.id == sessionID
                else {
                    return
                }
                guard activeRaid.bossHP > 0 else { return }

                let aliveBots = activeRaid.participants.filter {
                    $0.isBot && $0.connectionState == .inRaid
                        && $0.currentHP > 0
                }
                guard let bot = aliveBots.randomElement() else { return }
                if self.tryResolveBotSupportAction(bot, in: activeRaid) {
                    continue
                }

                let damage = self.resolvedBotDamage(for: bot)
                self.resolveRaidPlayerAction(
                    actorID: bot.id,
                    actorName: bot.displayName,
                    actionName: bot.role == .damageDealer
                        ? "Burst-Angriff" : "Bot-Angriff",
                    damage: damage,
                    broadcastUpdate: true
                )
            }
        }
    }

    private func applyRaidSnapshot(_ snapshot: RaidResumeSnapshot) {
        if var lobbyState = snapshot.lobbyState {
            lobbyState.participants = normalizeParticipants(
                lobbyState.participants
            )
            lobbyState.statusText = "Raid-Status wiederhergestellt"
            self.lobbyState = assignPartyCharacters(in: lobbyState)
        }

        if var activeRaid = snapshot.activeRaid {
            activeRaid.participants = normalizeParticipants(
                activeRaid.participants
            )
            activeRaid.combatLog.insert(
                "Raid-Snapshot vom Host wiederhergestellt.",
                at: 0
            )
            self.activeRaid = activeRaid
        }
    }

    private func resolveRaidPlayerAction(
        actorID: String,
        actorName: String,
        actionName: String,
        damage: Int,
        broadcastUpdate: Bool
    ) {
        guard var activeRaid else { return }

        let resultingBossHP = max(0, activeRaid.bossHP - damage)
        activeRaid.bossHP = resultingBossHP
        activeRaid.bossTargetParticipantID = nil
        activeRaid.bossTargetParticipantName = nil
        activeRaid.combatLog.insert(
            "\(actorName) nutzt \(actionName) und verursacht \(damage) Schaden.",
            at: 0
        )

        let resolvedAction = RaidResolvedPlayerAction(
            id: UUID().uuidString,
            sessionID: activeRaid.id,
            actorID: actorID,
            actorName: actorName,
            actionName: actionName,
            damage: damage,
            resultingBossHP: resultingBossHP,
            victory: resultingBossHP == 0
        )

        self.activeRaid = activeRaid
        self.latestResolvedRaidAction = resolvedAction

        if resultingBossHP == 0 {
            setRaidOutcome(victory: true)
            latestResolvedRaidBossAttack = nil
        }

        guard broadcastUpdate else { return }
        send(
            message: .init(
                kind: .stateSync,
                senderID: localPlayerID,
                timestamp: .now,
                payload: [
                    "event": "actionResolved",
                    "eventID": resolvedAction.id,
                    "sessionID": resolvedAction.sessionID,
                    "actorID": resolvedAction.actorID,
                    "actorName": resolvedAction.actorName,
                    "actionName": resolvedAction.actionName,
                    "damage": "\(resolvedAction.damage)",
                    "bossHP": "\(resolvedAction.resultingBossHP)",
                    "victory": resolvedAction.victory ? "true" : "false",
                ]
            )
        )

        if !resolvedAction.victory {
            scheduleHostRaidBossAttack(for: activeRaid)
        }
    }

    private func startRaidCountdown(seconds: Int) {
        raidCountdownTask?.cancel()
        let resolvedSeconds = max(0, seconds)
        guard resolvedSeconds > 0 else {
            raidCountdownRemaining = nil
            return
        }

        raidCountdownRemaining = resolvedSeconds
        raidCountdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var remaining = resolvedSeconds
            while remaining > 0, !Task.isCancelled {
                self.raidCountdownRemaining = remaining
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
            }
            self.raidCountdownRemaining = nil
            self.raidCountdownTask = nil
        }
    }

    private func scheduleHostRaidBossAttack(for activeRaid: ActiveRaidSession) {
        let sessionID = activeRaid.id
        guard pendingBossAttackSessionID != sessionID else { return }
        pendingBossAttackSessionID = sessionID
        let bossName = activeRaid.boss.name
        let damage = max(1, activeRaid.boss.attack)
        guard let target = selectRaidBossTarget(from: activeRaid)
        else {
            return
        }

        setRaidBossTarget(
            sessionID: sessionID,
            participantID: target.id,
            participantName: target.displayName,
            broadcastUpdate: true
        )

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard let self else { return }
            guard self.activeRaid?.id == sessionID else { return }
            self.resolveRaidBossAttack(
                sessionID: sessionID,
                bossName: bossName,
                targetParticipantID: target.id,
                targetParticipantName: target.displayName,
                damage: damage,
                broadcastUpdate: true
            )
        }
    }

    private func resolveRaidBossAttack(
        sessionID: String,
        bossName: String,
        targetParticipantID: String,
        targetParticipantName: String,
        damage: Int,
        broadcastUpdate: Bool
    ) {
        guard var activeRaid, activeRaid.id == sessionID else { return }
        guard
            let participantIndex = activeRaid.participants.firstIndex(where: {
                $0.id == targetParticipantID
            })
        else {
            return
        }

        let targetParticipant = activeRaid.participants[participantIndex]
        let mitigatedDamage = resolvedBossDamageAgainstParticipant(
            baseDamage: damage,
            participant: targetParticipant,
            boss: activeRaid.boss
        )
        let resultingHP = max(
            0,
            targetParticipant.currentHP - mitigatedDamage
        )
        activeRaid.participants[participantIndex].currentHP = resultingHP
        activeRaid.bossTargetParticipantID = nil
        activeRaid.bossTargetParticipantName = nil
        pendingBossAttackSessionID = nil
        let defeat = resultingHP == 0
        self.activeRaid = activeRaid

        let resolvedAttack = RaidResolvedBossAttack(
            id: UUID().uuidString,
            sessionID: sessionID,
            bossName: bossName,
            targetParticipantID: targetParticipantID,
            targetParticipantName: targetParticipantName,
            damage: mitigatedDamage,
            resultingHP: resultingHP,
            defeat: defeat
        )
        latestResolvedRaidBossAttack = resolvedAttack

        if defeat, targetParticipantID == localPlayerID {
            setRaidOutcome(victory: false)
        }

        guard broadcastUpdate else { return }
        send(
            message: .init(
                kind: .bossAttack,
                senderID: localPlayerID,
                timestamp: .now,
                payload: [
                    "eventID": resolvedAttack.id,
                    "sessionID": resolvedAttack.sessionID,
                    "bossName": resolvedAttack.bossName,
                    "targetParticipantID": resolvedAttack.targetParticipantID,
                    "targetParticipantName": resolvedAttack
                        .targetParticipantName,
                    "damage": "\(resolvedAttack.damage)",
                    "resultingHP": "\(resolvedAttack.resultingHP)",
                    "defeat": resolvedAttack.defeat ? "true" : "false",
                ]
            )
        )
    }

    private func selectRaidBossTarget(from activeRaid: ActiveRaidSession)
        -> RaidParticipant?
    {
        let aliveParticipants = activeRaid.participants.filter {
            $0.connectionState == .inRaid && $0.currentHP > 0
        }
        guard !aliveParticipants.isEmpty else { return nil }

        if Bool.random(),
            let weakest = aliveParticipants.min(by: {
                $0.currentHP < $1.currentHP
            })
        {
            return weakest
        }

        let weightedParticipants = aliveParticipants.flatMap { participant in
            Array(
                repeating: participant,
                count: max(
                    1,
                    resolvedTauntWeight(for: participant, in: activeRaid.boss)
                )
            )
        }

        return weightedParticipants.randomElement()
            ?? aliveParticipants.randomElement()
    }

    private func expandedBotRoleRotation(for boss: RaidBossDefinition)
        -> [RaidRoleDefinition]
    {
        let roles = boss.raidRoles
        guard !roles.isEmpty else { return [] }

        var expanded = [RaidRoleDefinition]()
        for role in roles {
            expanded.append(
                contentsOf: Array(
                    repeating: role,
                    count: max(1, role.preferredCount)
                )
            )
        }
        return expanded
    }

    private func assignPartyCharacters(in state: RaidLobbyState)
        -> RaidLobbyState
    {
        var updatedState = state
        let partyCharacters = state.boss.resolvedPartyCharacters
        guard !partyCharacters.isEmpty else { return updatedState }

        var rosterIndex = 0
        for index in updatedState.participants.indices {
            if updatedState.participants[index].isLocalPlayer {
                continue
            }

            let character = partyCharacters[rosterIndex % partyCharacters.count]
            updatedState.participants[index].characterName =
                character.displayName
            updatedState.participants[index].characterModel = character.model
            updatedState.participants[index].characterTexture =
                character.texture
            updatedState.participants[index].characterPreviewImage =
                character.previewImage
            rosterIndex += 1
        }

        return updatedState
    }

    private func resolvedParticipantMaxHP(
        baseHP: Int,
        role: RaidRoleType?,
        boss: RaidBossDefinition
    ) -> Int {
        guard let roleDefinition = roleDefinition(for: role, boss: boss) else {
            return baseHP
        }
        return max(
            baseHP,
            baseHP + (baseHP * roleDefinition.maxHPBonusPercent / 100)
        )
    }

    private func roleDefinition(
        for role: RaidRoleType?,
        boss: RaidBossDefinition
    )
        -> RaidRoleDefinition?
    {
        guard let role else { return nil }
        return boss.raidRoles.first(where: { $0.role == role })
    }

    private func resolvedTauntWeight(
        for participant: RaidParticipant,
        in boss: RaidBossDefinition
    ) -> Int {
        roleDefinition(for: participant.role, boss: boss)?.tauntWeight ?? 1
    }

    private func resolvedBossDamageAgainstParticipant(
        baseDamage: Int,
        participant: RaidParticipant,
        boss: RaidBossDefinition
    ) -> Int {
        guard
            let roleDefinition = roleDefinition(
                for: participant.role,
                boss: boss
            )
        else {
            return baseDamage
        }

        let reducedDamage = max(
            1,
            baseDamage
                - (baseDamage * roleDefinition.bossDamageReductionPercent / 100)
                - roleDefinition.shieldValue
        )
        return reducedDamage
    }

    private func resolvedBotDamage(for participant: RaidParticipant) -> Int {
        guard let activeRaid else { return Int.random(in: 160...320) }
        let baseDamage = Int.random(in: 160...320)
        guard
            let roleDefinition = roleDefinition(
                for: participant.role,
                boss: activeRaid.boss
            )
        else {
            return baseDamage
        }

        return max(
            1,
            baseDamage + (baseDamage * roleDefinition.attackBonusPercent / 100)
        )
    }

    private func tryResolveBotSupportAction(
        _ participant: RaidParticipant,
        in activeRaid: ActiveRaidSession
    ) -> Bool {
        guard
            let roleDefinition = roleDefinition(
                for: participant.role,
                boss: activeRaid.boss
            ),
            roleDefinition.healPower > 0
        else {
            return false
        }

        guard Bool.random() else { return false }
        guard
            let target = activeRaid.participants
                .filter({ $0.connectionState == .inRaid && $0.currentHP > 0 })
                .min(by: { lhs, rhs in
                    Double(lhs.currentHP) / Double(max(lhs.maxHP, 1))
                        < Double(rhs.currentHP) / Double(max(rhs.maxHP, 1))
                })
        else {
            return false
        }

        let needsHealing = target.currentHP < Int(Double(target.maxHP) * 0.82)
        guard needsHealing else { return false }

        applyBotHeal(
            actor: participant,
            targetParticipantID: target.id,
            targetParticipantName: target.displayName,
            amount: roleDefinition.healPower
        )
        return true
    }

    private func applyBotHeal(
        actor: RaidParticipant,
        targetParticipantID: String,
        targetParticipantName: String,
        amount: Int
    ) {
        guard var activeRaid else { return }
        guard
            let targetIndex = activeRaid.participants.firstIndex(where: {
                $0.id == targetParticipantID
            })
        else {
            return
        }

        let resultingHP = min(
            activeRaid.participants[targetIndex].maxHP,
            activeRaid.participants[targetIndex].currentHP + amount
        )
        activeRaid.participants[targetIndex].currentHP = resultingHP
        activeRaid.combatLog.insert(
            "\(actor.displayName) heilt \(targetParticipantName) um \(amount) HP.",
            at: 0
        )
        self.activeRaid = activeRaid
    }

    private func setRaidBossTarget(
        sessionID: String,
        participantID: String,
        participantName: String,
        broadcastUpdate: Bool
    ) {
        guard var activeRaid, activeRaid.id == sessionID else { return }
        activeRaid.bossTargetParticipantID = participantID
        activeRaid.bossTargetParticipantName = participantName
        activeRaid.combatLog.insert(
            "\(activeRaid.boss.name) fixiert \(participantName).",
            at: 0
        )
        self.activeRaid = activeRaid

        guard broadcastUpdate else { return }
        send(
            message: .init(
                kind: .stateSync,
                senderID: localPlayerID,
                timestamp: .now,
                payload: [
                    "event": "bossTargetSelected",
                    "sessionID": sessionID,
                    "participantID": participantID,
                    "participantName": participantName,
                ]
            )
        )
    }

    private func present(_ viewController: UIViewController) {
        guard
            let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
        else {
            lastErrorMessage =
                "Kein Root-ViewController zum Presenten gefunden."
            return
        }

        var topController = rootViewController
        while let presentedViewController = topController
            .presentedViewController
        {
            topController = presentedViewController
        }

        topController.present(viewController, animated: true)
    }
}

extension MultiplayerManager: GKLocalPlayerListener {
    nonisolated func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard
                let viewController = GKMatchmakerViewController(invite: invite)
            else {
                self.lastErrorMessage =
                    "Einladung konnte nicht geoeffnet werden."
                return
            }

            viewController.matchmakerDelegate = self
            self.isMatchmaking = true
            self.present(viewController)
        }
    }
}

extension MultiplayerManager: GKMatchmakerViewControllerDelegate {
    nonisolated func matchmakerViewControllerWasCancelled(
        _ viewController: GKMatchmakerViewController
    ) {
        Task { @MainActor [weak self] in
            viewController.dismiss(animated: true)
            self?.isMatchmaking = false
            self?.ensureLocalLobbyState()
        }
    }

    nonisolated func matchmakerViewController(
        _ viewController: GKMatchmakerViewController,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            viewController.dismiss(animated: true)
            self?.isMatchmaking = false
            self?.lastErrorMessage = error.localizedDescription
            self?.ensureLocalLobbyState()
        }
    }

    nonisolated func matchmakerViewController(
        _ viewController: GKMatchmakerViewController,
        didFind match: GKMatch
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            viewController.dismiss(animated: true)
            self.activeMatch?.delegate = nil
            self.activeMatch = match
            self.activeMatch?.delegate = self
            self.isMatchmaking = false

            let statusText =
                match.expectedPlayerCount == 0
                ? "Raid-Gruppe voll. Bereit machen."
                : "Gruppe gefunden. Warte auf weitere Spieler."
            self.syncLobbyParticipants(match: match, statusText: statusText)
        }
    }
}

extension MultiplayerManager: GKMatchDelegate {
    nonisolated func match(
        _ match: GKMatch,
        player: GKPlayer,
        didChange state: GKPlayerConnectionState
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            self.syncLobbyParticipants(
                match: match,
                statusText: state == .connected
                    ? "\(player.displayName) ist der Gruppe beigetreten."
                    : "\(player.displayName) hat die Verbindung verloren."
            )

            if state == .connected, self.isLocalRaidHost, self.activeRaid != nil
            {
                self.sendRaidSnapshot(to: [player])
            }
        }
    }

    nonisolated func match(
        _ match: GKMatch,
        didReceive data: Data,
        fromRemotePlayer player: GKPlayer
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard
                let message = try? JSONDecoder().decode(
                    RaidMessage.self,
                    from: data
                )
            else {
                return
            }

            switch message.kind {
            case .readyState:
                guard var lobbyState = self.lobbyState else { return }
                guard
                    let index = lobbyState.participants.firstIndex(where: {
                        $0.id == player.gamePlayerID
                    })
                else {
                    return
                }

                lobbyState.participants[index].isReady =
                    message.payload["ready"] == "true"
                lobbyState.statusText =
                    "\(player.displayName) hat den Bereitschaftsstatus aktualisiert."
                self.lobbyState = lobbyState

            case .raidStarted:
                self.startRaidIfPossible()

            case .playerAction:
                guard self.isLocalRaidHost else { return }
                if let damageText = message.payload["damage"],
                    let damage = Int(damageText)
                {
                    self.resolveRaidPlayerAction(
                        actorID: player.gamePlayerID,
                        actorName: player.displayName,
                        actionName: message.payload["action"] ?? "Aktion",
                        damage: damage,
                        broadcastUpdate: true
                    )
                }

            case .raidSnapshot:
                guard let snapshotBase64 = message.payload["snapshot"],
                    let snapshotData = Data(base64Encoded: snapshotBase64),
                    let snapshot = try? JSONDecoder().decode(
                        RaidResumeSnapshot.self,
                        from: snapshotData
                    )
                else {
                    return
                }

                self.applyRaidSnapshot(snapshot)

            case .stateSync:
                switch message.payload["event"] {
                case "actionResolved":
                    guard let eventID = message.payload["eventID"],
                        let sessionID = message.payload["sessionID"],
                        let actorID = message.payload["actorID"],
                        let actorName = message.payload["actorName"],
                        let actionName = message.payload["actionName"],
                        let damageText = message.payload["damage"],
                        let damage = Int(damageText),
                        let bossHPText = message.payload["bossHP"],
                        let bossHP = Int(bossHPText)
                    else {
                        return
                    }

                    self.syncRaidBossHP(bossHP)
                    self.appendRaidCombatLog(
                        "\(actorName) nutzt \(actionName) und verursacht \(damage) Schaden."
                    )
                    self.latestResolvedRaidAction = RaidResolvedPlayerAction(
                        id: eventID,
                        sessionID: sessionID,
                        actorID: actorID,
                        actorName: actorName,
                        actionName: actionName,
                        damage: damage,
                        resultingBossHP: bossHP,
                        victory: message.payload["victory"] == "true"
                    )

                    if message.payload["victory"] == "true" {
                        self.setRaidOutcome(victory: true)
                    }

                case "bossTargetSelected":
                    guard let sessionID = message.payload["sessionID"],
                        let participantID = message.payload["participantID"],
                        let participantName = message.payload[
                            "participantName"
                        ],
                        var activeRaid = self.activeRaid,
                        activeRaid.id == sessionID
                    else {
                        return
                    }

                    activeRaid.bossTargetParticipantID = participantID
                    activeRaid.bossTargetParticipantName = participantName
                    self.activeRaid = activeRaid
                    self.appendRaidCombatLog(
                        "\(activeRaid.boss.name) fixiert \(participantName)."
                    )

                default:
                    return
                }

            case .bossAttack:
                guard let eventID = message.payload["eventID"],
                    let sessionID = message.payload["sessionID"],
                    let bossName = message.payload["bossName"],
                    let targetParticipantID = message.payload[
                        "targetParticipantID"
                    ],
                    let targetParticipantName = message.payload[
                        "targetParticipantName"
                    ],
                    let damageText = message.payload["damage"],
                    let damage = Int(damageText),
                    let resultingHPText = message.payload["resultingHP"],
                    let resultingHP = Int(resultingHPText)
                else {
                    return
                }

                self.syncRaidParticipantHP(
                    participantID: targetParticipantID,
                    hp: resultingHP
                )
                self.latestResolvedRaidBossAttack = RaidResolvedBossAttack(
                    id: eventID,
                    sessionID: sessionID,
                    bossName: bossName,
                    targetParticipantID: targetParticipantID,
                    targetParticipantName: targetParticipantName,
                    damage: damage,
                    resultingHP: resultingHP,
                    defeat: message.payload["defeat"] == "true"
                )

                if targetParticipantID == self.localPlayerID,
                    message.payload["defeat"] == "true"
                {
                    self.setRaidOutcome(victory: false)
                }

            case .raidEnded:
                break
            }
        }
    }
}
