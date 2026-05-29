//
//  BattleView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

enum Turn {
    case player
    case enemy
}

struct BattleTutorialConfig {
    let title: String
    let objective: String
    let retreatEnemyIndex: Int?
    let enemyRetreatThreshold: CGFloat?
    let onEnemyRetreat: () -> Void
    let onBattleComplete: () -> Void
}

struct BattleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var multiplayerManager: MultiplayerManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerDeckCardSlot.slotIndex) private var deckSlots:
        [PlayerDeckCardSlot]
    @Query(sort: \OwnedAbilityCard.cardID) private var ownedCards:
        [OwnedAbilityCard]
    @Query(sort: \PlayerCharacterProgress.characterID) private
        var characterProgress: [PlayerCharacterProgress]
    @Query(sort: \PlayerAccountProgress.id) private var accountProgress:
        [PlayerAccountProgress]

    let player: CharacterStats
    let enemy: CharacterStats
    let enemiesOverride: [CharacterStats]?
    let onExit: () -> Void
    let tutorialConfig: BattleTutorialConfig?
    let raidConfiguration: RaidBattleConfiguration?
    let onRaidBossHPChanged: ((Int) -> Void)?
    let onRaidCombatLog: ((String) -> Void)?
    let onRaidFinished: ((Bool) -> Void)?

    @State private var currentTurn: Turn = .player
    @State private var playerHP: CGFloat = 1
    @State private var enemyHPs: [CGFloat] = []
    @State private var selectedEnemyIndex = 0
    @State private var showVictory = false
    @State private var showDefeat = false
    @State private var isAuto = false
    @AppStorage("battleAutoModeEnabled") private var savedAutoMode = false
    @AppStorage("battleFastModeEnabled") private var isFast = false
    @State private var playerAttackID = 0
    @State private var allyAttackID = 0
    @State private var allyAttackerParticipantID: String?
    @State private var enemyAttackID = 0
    @State private var attackingEnemyIndex: Int?
    @State private var didAwardRewards = false
    @State private var currentParticleEffect: String?
    @State private var playerMana: Double = 60
    @State private var awardedXP = 0
    @State private var awardedAscendedXP = 0
    @State private var awardedRewards: [CurrencyAmount] = []
    @State private var awardedCharacterRewards: [GlobeBattle.CharacterReward] =
        []
    @State private var awardedSkinRewards: [StorePackSkinReward] = []
    @State private var awardedCardRewards: [GlobeBattle.CardReward] = []
    @State private var levelBeforeVictory = 1
    @State private var levelAfterVictory = 1
    @State private var ascendedLevelBeforeVictory = 1
    @State private var ascendedLevelAfterVictory = 1
    @State private var autoTask: Task<Void, Never>?
    @State private var turnTask: Task<Void, Never>?
    @State private var manaRegenTask: Task<Void, Never>?
    @State private var comboWindowTask: Task<Void, Never>?
    @State private var inspectedCard: AbilityCardDefinition?
    @State private var cardLongPressActive = false
    @State private var cardPressTask: Task<Void, Never>?
    @State private var isResolvingTurn = false

    private var rewardCurrenciesForVictory: [CurrencyDefinition] {
        var definitionsByCode = [String: CurrencyDefinition]()

        for currency in loadCurrencyDefinitions() {
            definitionsByCode[currency.code] = currency
        }

        for currency in raidConfiguration?.rewardCurrencyDefinitions ?? [] {
            definitionsByCode[currency.code] = currency
        }

        return definitionsByCode.values.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.code < rhs.code
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
    @State private var didTriggerTutorialRetreat = false
    @State private var currentParticleTargetIndices: [Int] = []
    @State private var currentComboStepIndex = 0
    @State private var currentComboStep: BattleComboStepDefinition?
    @State private var currentComboInputs: [String] = []
    @State private var activeComboID: String?
    @State private var showsComboLibrary = false
    @State private var didTriggerHoldAttack = false

    private let maxMana: Double = 100
    private let baseAttackManaGain: Double = 18
    private let turnManaGain: Double = 12
    private let manaRegenPerTick: Double = 2
    private let manaRegenTickMilliseconds = 450
    private let actionFrameCommitMilliseconds = 16
    private let actionCooldownTickMilliseconds = 40
    private let minimumNormalEnemyHits: CGFloat = 2.5
    private let minimumBossEnemyHits: CGFloat = 5.5
    private let maximumEnemyDifficultyStep = 35.0
    private let enemyHPGrowthPerDifficulty = 1.025
    private let enemyAttackGrowthPerDifficulty = 1.018
    private let enemyMinimumHPGrowthPerDifficulty = 1.015

    private var battleCombo: BattleComboDefinition {
        let combos = loadBattleComboDefinitions()
        if let activeComboID,
            let activeCombo = combos.first(where: { $0.id == activeComboID })
        {
            return activeCombo
        }

        return combos.first { $0.isDefault == true } ?? combos.first
            ?? BattleComboDefinition(
            id: "fallback_combo",
            name: "Fallback Combo",
            description: "Basis Combo",
            inputSequence: ["tap"],
            isDefault: true,
            sortOrder: 999,
            comboWindow: 1.15,
            resetAfter: 1.8,
            steps: [
                BattleComboStepDefinition(
                    id: "dash",
                    input: "tap",
                    label: "Dash",
                    style: BattleComboStyle.dash.rawValue,
                    damageMultiplier: 1.0,
                    hitDelay: 0.22,
                    holdDuration: 0.25,
                    slowMotion: false,
                    particleEffect: nil
                )
            ]
        )
    }

    init(
        player: CharacterStats,
        enemy: CharacterStats,
        enemiesOverride: [CharacterStats]? = nil,
        onExit: @escaping () -> Void,
        tutorialConfig: BattleTutorialConfig? = nil,
        raidConfiguration: RaidBattleConfiguration? = nil,
        onRaidBossHPChanged: ((Int) -> Void)? = nil,
        onRaidCombatLog: ((String) -> Void)? = nil,
        onRaidFinished: ((Bool) -> Void)? = nil
    ) {
        self.player = player
        self.enemy = enemy
        self.enemiesOverride = enemiesOverride
        self.onExit = onExit
        self.tutorialConfig = tutorialConfig
        self.raidConfiguration = raidConfiguration
        self.onRaidBossHPChanged = onRaidBossHPChanged
        self.onRaidCombatLog = onRaidCombatLog
        self.onRaidFinished = onRaidFinished
    }

    private var activeCards: [AbilityCardDefinition] {
        let slotLimit = loadDeckConfiguration().resolvedSlotCount
        return
            deckSlots
            .sorted { $0.slotIndex < $1.slotIndex }
            .prefix(slotLimit)
            .compactMap { slot in
                gameState.abilityCards.first { $0.id == slot.cardID }
            }
    }

    private var playerProgress: PlayerCharacterProgress? {
        characterProgress.first { $0.characterID == player.model }
    }

    private var playerLevel: Int {
        playerProgress?.level ?? 1
    }

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    private var leveledPlayer: CharacterStats {
        PlayerInventoryStore.scaledCharacterStats(
            for: player,
            characterLevel: playerLevel,
            ascendedLevel: ascendedLevel,
            in: modelContext
        )
    }

    private var skillBonuses: CharacterSkillBonusTotals {
        PlayerInventoryStore.characterSkillBonuses(
            for: player.model,
            in: modelContext
        )
    }

    private var battleEnemies: [CharacterStats] {
        if let raidConfiguration {
            return [raidConfiguration.boss]
        }

        if let enemiesOverride, !enemiesOverride.isEmpty {
            return enemiesOverride
        }

        if let selectedBattle = gameState.selectedBattle {
            return selectedBattle.battleEnemies
        }

        return [enemy]
    }

    private var activeEnemies: [CharacterStats] {
        battleEnemies.indices.map { scaledEnemy(battleEnemies[$0], at: $0) }
    }

    private var currentEnemy: CharacterStats {
        let index = safeSelectedEnemyIndex
        return activeEnemies[index]
    }

    private var safeSelectedEnemyIndex: Int {
        guard !activeEnemies.isEmpty else { return 0 }
        return min(max(selectedEnemyIndex, 0), activeEnemies.count - 1)
    }

    private var aliveEnemyIndices: [Int] {
        activeEnemies.indices.filter {
            enemyHPs.indices.contains($0) && enemyHPs[$0] > 0
        }
    }

    private var isBossWave: Bool {
        if raidConfiguration != nil {
            return true
        }
        guard gameState.selectedBattle?.boss != nil else { return false }
        return safeSelectedEnemyIndex == activeEnemies.count - 1
    }

    private func isBossEnemy(at index: Int) -> Bool {
        if raidConfiguration != nil {
            return true
        }
        guard gameState.selectedBattle?.boss != nil else { return false }
        return index == battleEnemies.count - 1
    }

    private var battleXPReward: Int {
        if let raidConfiguration {
            return raidConfiguration.xpReward
        }
        let difficulty = gameState.selectedBattle?.difficulty ?? 1
        let baseXP =
            gameState.selectedBattle?.xpReward
            ?? (160 + difficulty * 45 + battleEnemies.count * 30)
        let difficultyBonus = 1 + Double(max(0, difficulty - 1)) * 0.12
        let groupBonus = 1 + Double(max(0, battleEnemies.count - 1)) * 0.18
        let bossBonus = gameState.selectedBattle?.boss == nil ? 1.0 : 1.35

        return max(
            baseXP,
            Int(
                (Double(baseXP) * difficultyBonus * groupBonus * bossBonus)
                    .rounded()
            )
        )
    }

    private var battleSpeedMultiplier: Double {
        isFast ? 2.0 : 1.0
    }

    private func speedAdjustedMilliseconds(_ milliseconds: Int) -> Int {
        max(1, Int((Double(milliseconds) / battleSpeedMultiplier).rounded()))
    }

    private func effectiveAttackSpeed(for fighter: CharacterStats) -> Double {
        if let attackSpeed = fighter.attackSpeed, attackSpeed > 0 {
            return max(0.35, min(attackSpeed, 1.4))
        }

        return max(0.35, min(Double(fighter.attack) / 420.0, 1.25))
    }

    @MainActor
    private func waitForActionCooldown(
        for fighter: CharacterStats,
        baseDuration: Double
    ) async -> Bool {
        var progress = 0.0
        let tickSeconds = Double(actionCooldownTickMilliseconds) / 1_000
        let normalizedBaseDuration = max(0.05, baseDuration)

        while progress < 1 {
            try? await Task.sleep(
                for: .milliseconds(actionCooldownTickMilliseconds)
            )
            guard !Task.isCancelled else { return false }

            let currentSpeed =
                effectiveAttackSpeed(for: fighter)
                * battleSpeedMultiplier
            progress += tickSeconds * currentSpeed / normalizedBaseDuration
        }

        return true
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                player: leveledPlayer,
                enemies: activeEnemies,
                raidParticipants: raidConfiguration != nil
                    ? multiplayerManager.activeRaid?.participants : nil,
                enemyHPs: enemyHPs,
                selectedEnemyIndex: safeSelectedEnemyIndex,
                playerAttackID: playerAttackID,
                allyAttackID: allyAttackID,
                allyAttackerParticipantID: allyAttackerParticipantID,
                enemyAttackID: enemyAttackID,
                attackingEnemyIndex: attackingEnemyIndex,
                particleEffect: currentParticleEffect,
                particleTargetIndices: currentParticleTargetIndices,
                comboStep: currentComboStep,
                particleEffects: gameState.particleEffects,
                groundTexture: raidConfiguration?.groundTexture
                    ?? gameState.activeGroundTexture,
                skyboxTexture: raidConfiguration?.skyboxTexture
                    ?? gameState.activeSkyboxTexture,
                battleSpeedMultiplier: battleSpeedMultiplier,
                onSelectEnemy: { index in
                    selectEnemy(index)
                }
            )
            .id(
                "\(activeEnemies.map(\.id).joined(separator: "-"))-\(playerLevel)"
            )
            .ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .gesture(basicAttackGesture)

            battleHUD

            if let tutorialConfig, !showVictory, !showDefeat {
                tutorialBanner(tutorialConfig)
                    .zIndex(24)
            }

            if showVictory {
                VictoryView(
                    currencies: rewardCurrenciesForVictory,
                    rewards: awardedRewards,
                    characterRewards: awardedCharacterRewards,
                    skinRewards: awardedSkinRewards,
                    cardRewards: awardedCardRewards,
                    xpReward: awardedXP,
                    ascendedXPReward: awardedAscendedXP,
                    levelBefore: levelBeforeVictory,
                    levelAfter: levelAfterVictory,
                    ascendedLevelBefore: ascendedLevelBeforeVictory,
                    ascendedLevelAfter: ascendedLevelAfterVictory,
                    defeatedEnemies: battleEnemies.count,
                    onContinue: {
                        onExit()
                    }
                )
                .zIndex(30)
            }

            if showDefeat {
                defeatOverlay
                    .zIndex(30)
            }

            if let raidConfiguration,
                let countdown = multiplayerManager.raidCountdownRemaining,
                countdown > 0
            {
                raidCountdownOverlay(
                    seconds: countdown,
                    bossName: raidConfiguration.boss.name
                )
                .zIndex(28)
            }

            if let inspectedCard {
                cardInfoOverlay(for: inspectedCard)
                    .zIndex(25)
            }
        }
        .onAppear {
            if let raidConfiguration {
                playerHP =
                    CGFloat(raidConfiguration.localParticipantHP)
                    / max(CGFloat(raidConfiguration.localParticipantMaxHP), 1)
            } else {
                playerHP = 1
            }
            enemyHPs = Array(repeating: 1, count: activeEnemies.count)
            if let raidConfiguration, enemyHPs.indices.contains(0) {
                enemyHPs[0] =
                    CGFloat(raidConfiguration.startingBossHP)
                    / max(raidConfiguration.boss.hp, 1)
            }
            playerMana = 60
            selectedEnemyIndex = 0
            isAuto = savedAutoMode
            startManaRegen()
            if savedAutoMode && currentTurn == .player {
                startAutoAttack()
            }
        }
        .onChange(of: isFast) {
            if isAuto {
                startAutoAttack()
            }
        }
        .onChange(of: isAuto) { _, enabled in
            if enabled {
                resumeAutoAttackIfPossible()
            } else if !enabled {
                stopAutoAttack()
            }
        }
        .onChange(of: currentTurn) { _, _ in
            resumeAutoAttackIfPossible()
        }
        .onChange(of: isResolvingTurn) { _, _ in
            resumeAutoAttackIfPossible()
        }
        .onChange(of: multiplayerManager.latestResolvedRaidAction?.id) { _, _ in
            applyResolvedRaidActionIfNeeded()
        }
        .onChange(of: multiplayerManager.latestResolvedRaidBossAttack?.id) {
            _,
            _ in
            applyResolvedRaidBossAttackIfNeeded()
        }
        .sheet(isPresented: $showsComboLibrary) {
            BattleComboLibraryView(
                combos: loadBattleComboDefinitions(),
                activeComboID: battleCombo.id
            )
        }
        .onDisappear {
            stopAutoAttack()
            turnTask?.cancel()
            manaRegenTask?.cancel()
            comboWindowTask?.cancel()
            cardPressTask?.cancel()
        }
    }

    private var battleHUD: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 14)
                .padding(.top, 14)

            ZStack(alignment: .top) {
                VStack(spacing: 8) {
                    enemyHPPanel
                    if raidConfiguration != nil, isLocalRaidTargeted {
                        raidTargetWarning
                    }
                    targetStrip
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity)

                HStack(alignment: .top, spacing: 0) {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        cardRail

                        if raidConfiguration != nil {
                            raidPartyPanel
                        }
                    }
                    .padding(.trailing, 14)
                    .padding(.top, 16)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                playerHPPanel
                    .frame(maxWidth: .infinity, alignment: .center)

                bottomControls
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .foregroundStyle(.white)
    }

    private var basicAttackGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in }
            .onEnded { value in
                if didTriggerHoldAttack {
                    didTriggerHoldAttack = false
                    return
                }
                attack(with: nil, input: comboInput(for: value.translation))
            }
            .simultaneously(
                with: LongPressGesture(minimumDuration: 0.38)
                    .onEnded { _ in
                        didTriggerHoldAttack = true
                        attack(with: nil, input: "hold")
                    }
            )
    }

    private func comboInput(for translation: CGSize) -> String {
        let horizontal = translation.width
        let vertical = translation.height

        guard max(abs(horizontal), abs(vertical)) >= 28 else {
            return "tap"
        }

        if abs(horizontal) > abs(vertical) {
            return horizontal < 0 ? "swipeLeft" : "swipeRight"
        }

        return vertical < 0 ? "swipeUp" : "swipeDown"
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 12, weight: .black))
                    .lineLimit(1)
                Text("Lv.\(playerLevel)  XP \(playerProgress?.xp ?? 0)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                onExit()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 38, height: 30)
                    .background(Color.black.opacity(0.58), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func tutorialBanner(_ config: BattleTutorialConfig) -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.title.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.yellow)
                Text(config.objective)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Color.black.opacity(0.78),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .padding(.top, 56)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var enemyTitle: String {
        let prefix = isBossWave ? "BOSS  " : ""
        return
            "\(prefix)\(currentEnemy.name.uppercased())  [\(GameElement(currentEnemy.element).displayName)]"
    }

    private var enemyHPPanel: some View {
        battleHPBar(
            title: enemyTitle,
            value: enemyHPs.indices.contains(safeSelectedEnemyIndex)
                ? enemyHPs[safeSelectedEnemyIndex] : 0,
            maximumHP: currentEnemy.hp,
            width: 200
        )
    }

    private var playerHPPanel: some View {
        let localRaidParticipant = multiplayerManager.activeRaid?.participants
            .first(where: \.isLocalPlayer)
        let displayedPlayerHP =
            raidConfiguration != nil
            ? CGFloat(localRaidParticipant?.currentHP ?? 0) : leveledPlayer.hp
        let displayedPlayerMaxHP =
            raidConfiguration != nil
            ? CGFloat(localRaidParticipant?.maxHP ?? 1) : leveledPlayer.hp
        return VStack(alignment: .leading, spacing: 5) {
            battleHPBar(
                title: player.name.uppercased(),
                value: playerHP,
                maximumHP: displayedPlayerMaxHP,
                width: 200
            )

            HStack(spacing: 8) {
                Text("DMG \(Int(leveledPlayer.attack))")
                Text(
                    "HP \(Int(displayedPlayerHP))/\(Int(displayedPlayerMaxHP))"
                )
                Text(GameElement(player.element).displayName)
                    .foregroundStyle(GameElement(player.element).color)
            }
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.78))

            manaBar
        }
    }

    private var manaBar: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 9, weight: .black))
                Text("MANA \(Int(playerMana))/\(Int(maxMana))")
                    .font(.system(size: 9, weight: .black))
            }
            .foregroundStyle(.cyan.opacity(0.9))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.68))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue.opacity(0.84)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                8,
                                geo.size.width * CGFloat(playerMana / maxMana)
                            )
                        )
                        .animation(
                            .easeInOut(duration: 0.22),
                            value: playerMana
                        )
                    Capsule()
                        .stroke(.white.opacity(0.32), lineWidth: 1)
                }
            }
            .frame(width: 220, height: 8)
        }
    }

    private var raidPartyPanel: some View {
        let participants = multiplayerManager.activeRaid?.participants ?? []
        let targetedParticipantID = multiplayerManager.activeRaid?
            .bossTargetParticipantID

        return VStack(alignment: .leading, spacing: 8) {
            Text("RAID PARTY")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.yellow)

            VStack(spacing: 6) {
                ForEach(participants) { participant in
                    raidParticipantCard(
                        participant,
                        targetedParticipantID: targetedParticipantID
                    )
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 118, alignment: .leading)
        .background(
            Color.black.opacity(0.52),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func raidParticipantCard(
        _ participant: RaidParticipant,
        targetedParticipantID: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {

            HStack(spacing: 3) {
                if participant.isLocalPlayer {
                    raidMiniBadge("YOU", fill: .cyan, text: .black)
                }

                if participant.isHost {
                    raidMiniBadge("HOST", fill: .orange, text: .black)
                }

                if targetedParticipantID == participant.id {
                    raidMiniBadge("TARGET", fill: .red, text: .white)
                }
            }
            .padding(4)
            Text(participant.characterName ?? participant.displayName)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let roleName = participant.roleName {
                Text(roleName.uppercased())
                    .font(.system(size: 6, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.74))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: participant.currentHP > 0
                                    ? [.green, .mint]
                                    : [.red.opacity(0.7), .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                4,
                                proxy.size.width
                                    * CGFloat(participant.healthProgress)
                            )
                        )
                }
            }
            .frame(height: 5)

            Text("\(participant.currentHP)/\(participant.maxHP)")
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(5)
        .background(
            targetedParticipantID == participant.id
                ? Color.red.opacity(0.16) : Color.black.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func raidMiniBadge(
        _ title: String,
        fill: Color,
        text: Color
    ) -> some View {
        Text(title)
            .font(.system(size: 6, weight: .black))
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(fill.opacity(0.92), in: Capsule())
            .foregroundStyle(text)
    }

    private var raidTargetWarning: some View {
        Text("BOSS TARGETING YOU")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.84), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.24), lineWidth: 1)
            }
    }

    private var targetStrip: some View {
        HStack(spacing: 6) {
            ForEach(activeEnemies.indices, id: \.self) { index in
                Button {
                    selectEnemy(index)
                } label: {
                    VStack(spacing: 2) {
                        Image(
                            systemName: index == safeSelectedEnemyIndex
                                ? "scope" : "person.fill"
                        )
                        .font(.system(size: 10, weight: .black))
                        Text("T\(index + 1)")
                            .font(.system(size: 7, weight: .black))
                    }
                    .foregroundStyle(
                        enemyHPs.indices.contains(index) && enemyHPs[index] > 0
                            ? .white : .white.opacity(0.32)
                    )
                    .frame(width: 34, height: 30)
                    .background(
                        targetColor(for: index),
                        in: RoundedRectangle(
                            cornerRadius: 7,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(
                                index == safeSelectedEnemyIndex
                                    ? .yellow : .white.opacity(0.20),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .disabled(
                    !(enemyHPs.indices.contains(index) && enemyHPs[index] > 0)
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Color.black.opacity(0.42),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func targetColor(for index: Int) -> Color {
        guard enemyHPs.indices.contains(index), enemyHPs[index] > 0 else {
            return Color.black.opacity(0.28)
        }
        return index == safeSelectedEnemyIndex
            ? Color.red.opacity(0.72) : Color.black.opacity(0.48)
    }

    private var cardRail: some View {
        VStack(spacing: 8) {
            ForEach(activeCards.prefix(5)) { card in
                let progress = cardProgress(for: card)
                let canUse = playerMana >= Double(card.resolvedManaCost)

                ZStack(alignment: .bottomTrailing) {
                    cardImage(card.image)
                        .frame(width: 64, height: 88)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 5,
                                style: .continuous
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5).stroke(
                                GameElement(card.element).color.opacity(
                                    0.85
                                ),
                                lineWidth: 2
                            )
                        )
                        .opacity(canUse ? 1 : 0.44)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("★\(progress.stars) Lv.\(progress.level)")
                            .font(.system(size: 8, weight: .black))
                        Text("\(card.resolvedManaCost) MP")
                            .font(.system(size: 8, weight: .black))
                        Text(
                            "x\(String(format: "%.1f", effectiveCardMultiplier(card)))"
                        )
                        .font(.system(size: 8, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(
                        Color.black.opacity(0.76),
                        in: RoundedRectangle(
                            cornerRadius: 5,
                            style: .continuous
                        )
                    )
                    .padding(3)
                }
                .contentShape(Rectangle())
                .gesture(cardPressGesture(for: card, canUse: canUse))
            }
        }
    }

    private func cardPressGesture(
        for card: AbilityCardDefinition,
        canUse: Bool
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard cardPressTask == nil else { return }
                cardLongPressActive = false
                cardPressTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    guard !Task.isCancelled else { return }
                    cardLongPressActive = true
                    withAnimation(.easeInOut(duration: 0.16)) {
                        inspectedCard = card
                    }
                }
            }
            .onEnded { _ in
                cardPressTask?.cancel()
                cardPressTask = nil

                if cardLongPressActive {
                    cardLongPressActive = false
                    withAnimation(.easeInOut(duration: 0.12)) {
                        inspectedCard = nil
                    }
                    return
                }

                guard canUse else { return }
                attack(with: card, input: "tap")
            }
    }

    private func cardInfoOverlay(for card: AbilityCardDefinition) -> some View {
        let progress = cardProgress(for: card)
        let element = GameElement(card.element)
        let enemyElement = GameElement(currentEnemy.element)
        let elementMultiplier = elementalMultiplier(for: card)
        let totalMultiplier = effectiveCardMultiplier(card) * elementMultiplier
        let effectivenessText =
            elementMultiplier > 1.05
            ? "Effektiv" : elementMultiplier < 0.95 ? "Schwach" : "Neutral"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                cardImage(card.image)
                    .frame(width: 72, height: 98)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(
                            element.color,
                            lineWidth: 2
                        )
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name.uppercased())
                        .font(.system(size: 17, weight: .black))
                        .lineLimit(2)
                    Text(
                        "★ \(progress.stars)   Lv. \(progress.level)/\(card.resolvedMaxLevel)"
                    )
                    .font(.system(size: 12, weight: .heavy))
                    Text("\(card.resolvedManaCost) Mana")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.cyan)
                    Text(element.displayName)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(element.color)
                }
            }

            Divider()
                .overlay(.white.opacity(0.28))

            VStack(alignment: .leading, spacing: 5) {
                Text(
                    "Gegner: \(currentEnemy.name) [\(enemyElement.displayName)]"
                )
                Text(
                    "\(effectivenessText) gegen Ziel  x\(String(format: "%.2f", elementMultiplier))"
                )
                Text(
                    "Gesamt Schaden  x\(String(format: "%.2f", totalMultiplier))"
                )
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.84))

            Text(card.description)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: 310, alignment: .leading)
        .background(
            Color.black.opacity(0.86),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(element.color.opacity(0.85), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 18)
        .allowsHitTesting(false)
    }

    private var bottomControls: some View {
        HStack(spacing: 8) {
            Button {
                selectNextTarget()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "scope")
                        .font(.system(size: 15, weight: .black))
                    Text("TARGET")
                        .font(.system(size: 7, weight: .black))
                }
                .frame(width: 58, height: 42)
                .background(
                    Color.black.opacity(0.58),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button {
                setAutoMode(!isAuto)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: isAuto ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .black))
                    Text("AUTO")
                        .font(.system(size: 7, weight: .black))
                }
                .frame(width: 58, height: 42)
                .background(
                    isAuto
                        ? Color.green.opacity(0.75) : Color.black.opacity(0.58),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button {
                showsComboLibrary = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 15, weight: .black))
                    Text("COMBO")
                        .font(.system(size: 7, weight: .black))
                }
                .frame(width: 58, height: 42)
                .background(
                    Color.purple.opacity(0.72),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Button {
                isFast.toggle()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: isFast ? "forward.fill" : "forward")
                        .font(.system(size: 15, weight: .black))
                    Text(isFast ? "2X" : "1X")
                        .font(.system(size: 7, weight: .black))
                }
                .frame(width: 58, height: 42)
                .background(
                    isFast
                        ? Color.cyan.opacity(0.75) : Color.black.opacity(0.58),
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var defeatOverlay: some View {
        let isRaidBattle = raidConfiguration != nil

        return ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.red)

                VStack(spacing: 6) {
                    Text(isRaidBattle ? "RAID FAILED" : "DEFEAT")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.white)

                    Text(
                        isRaidBattle
                            ? "Deine Gruppe wurde im Raid besiegt."
                            : "Dein Team wurde besiegt."
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                }

                HStack(spacing: 10) {
                    Button {
                        retryBattle()
                    } label: {
                        Label("Neu versuchen", systemImage: "arrow.clockwise")
                            .font(.system(size: 13, weight: .black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                .white,
                                in: RoundedRectangle(
                                    cornerRadius: 8,
                                    style: .continuous
                                )
                            )
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)

                    Button {
                        returnHomeFromDefeat()
                    } label: {
                        Label(
                            isRaidBattle ? "Zurueck zur Lobby" : "Home",
                            systemImage: isRaidBattle
                                ? "arrow.uturn.backward.circle.fill"
                                : "house.fill"
                        )
                        .font(.system(size: 13, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Color.black.opacity(0.46),
                            in: RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                            )
                            .stroke(.white.opacity(0.24), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(
                Color.black.opacity(0.82),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.red.opacity(0.72), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
            .padding(.horizontal, 18)
        }
    }

    private func battleHPBar(
        title: String,
        value: CGFloat,
        maximumHP: CGFloat,
        width: CGFloat
    ) -> some View {
        let safe = max(0, min(1, value))
        let currentHP = max(0, Int((maximumHP * safe).rounded()))

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .lineLimit(1)
                Spacer()
                Text("\(currentHP)/\(Int(maximumHP))")
                    .font(.system(size: 10, weight: .heavy))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.80))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint, .green.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * safe))
                        .animation(.easeInOut(duration: 0.22), value: safe)
                    Capsule()
                        .stroke(.white.opacity(0.36), lineWidth: 1)
                }
            }
            .frame(height: 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(width: width)
        .background(
            Color.black.opacity(0.50),
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
    }

    @ViewBuilder
    private func cardImage(_ imageName: String) -> some View {
        RemoteAssetImage(imageName) {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.86), .blue.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
    }

    private func retryBattle() {
        if raidConfiguration != nil {
            multiplayerManager.restartRaidWithFullHP()
            guard let activeRaid = multiplayerManager.activeRaid else { return }

            if let localParticipant = activeRaid.participants.first(
                where: \.isLocalPlayer
            ) {
                playerHP =
                    CGFloat(localParticipant.currentHP)
                    / max(CGFloat(localParticipant.maxHP), 1)
            } else {
                playerHP = 1
            }

            if enemyHPs.indices.contains(0) {
                enemyHPs = Array(repeating: 0, count: activeEnemies.count)
                enemyHPs[0] =
                    CGFloat(activeRaid.bossHP)
                    / max(activeEnemies[0].hp, 1)
            } else {
                enemyHPs = Array(repeating: 1, count: activeEnemies.count)
            }
        } else {
            playerHP = 1
            enemyHPs = Array(repeating: 1, count: activeEnemies.count)
        }

        playerMana = 60
        selectedEnemyIndex = 0
        currentTurn = .player
        turnTask?.cancel()
        turnTask = nil
        resetComboChain()
        isResolvingTurn = false
        currentParticleTargetIndices = []
        currentParticleEffect = nil
        attackingEnemyIndex = nil
        showVictory = false
        showDefeat = false
        didAwardRewards = false
        startManaRegen()
    }

    private func returnHomeFromDefeat() {
        isAuto = false
        autoTask?.cancel()
        turnTask?.cancel()
        manaRegenTask?.cancel()
        resetComboChain()
        attackingEnemyIndex = nil
        showDefeat = false
        onExit()
    }

    private func selectEnemy(_ index: Int) {
        guard enemyHPs.indices.contains(index), enemyHPs[index] > 0 else {
            return
        }
        selectedEnemyIndex = index
    }

    private func selectNextTarget(after index: Int? = nil) {
        guard !aliveEnemyIndices.isEmpty else { return }
        let startIndex = index ?? safeSelectedEnemyIndex
        if let next = aliveEnemyIndices.first(where: { $0 > startIndex }) {
            selectedEnemyIndex = next
        } else {
            selectedEnemyIndex = aliveEnemyIndices[0]
        }
    }

    private func ownedCount(for card: AbilityCardDefinition) -> Int {
        max(1, ownedCards.first { $0.cardID == card.id }?.count ?? 1)
    }

    private func cardProgress(for card: AbilityCardDefinition)
        -> CardBattleProgress
    {
        let count = ownedCount(for: card)
        let level = min(
            card.resolvedMaxLevel,
            1 + (count - 1) / card.resolvedDuplicatesPerLevel
        )
        let stars = min(
            card.resolvedMaxStars,
            1 + (level - 1) / card.resolvedLevelsPerStar
        )
        return CardBattleProgress(level: level, stars: stars)
    }

    private func effectiveCardMultiplier(_ card: AbilityCardDefinition)
        -> Double
    {
        let progress = cardProgress(for: card)
        let levelGrowth = pow(
            card.resolvedDamageGrowth,
            Double(progress.level - 1)
        )
        let starGrowth = pow(1.12, Double(progress.stars - 1))
        let elementBonus = skillBonuses.damagePercent(for: card.element)
        return card.damageMultiplier * levelGrowth * starGrowth
            * max(0.1, 1 + skillBonuses.cardDamagePercent + elementBonus)
    }

    private func elementalMultiplier(for card: AbilityCardDefinition) -> Double
    {
        elementalMultiplier(for: card, enemyIndex: safeSelectedEnemyIndex)
    }

    private func elementalMultiplier(
        for card: AbilityCardDefinition,
        enemyIndex: Int
    ) -> Double {
        guard activeEnemies.indices.contains(enemyIndex) else { return 1.0 }
        return GameElement(card.element).multiplier(
            against: GameElement(activeEnemies[enemyIndex].element)
        )
    }

    private func targetIndices(for card: AbilityCardDefinition?) -> [Int] {
        if let card, card.isAOE {
            return aliveEnemyIndices
        }
        return [safeSelectedEnemyIndex]
    }

    private func recoverMana(_ amount: Double) {
        playerMana = min(maxMana, playerMana + amount)
    }

    private func startManaRegen() {
        manaRegenTask?.cancel()
        manaRegenTask = Task { @MainActor in
            while !Task.isCancelled {
                if showVictory || showDefeat { return }
                recoverMana(
                    manaRegenPerTick
                        * max(0.1, 1 + skillBonuses.manaRegenPercent)
                )
                try? await Task.sleep(
                    for: .milliseconds(
                        speedAdjustedMilliseconds(manaRegenTickMilliseconds)
                    )
                )
            }
        }
    }

    private func scaledEnemy(_ base: CharacterStats, at index: Int)
        -> CharacterStats
    {
        let difficulty = Double(
            raidConfiguration?.difficulty ?? gameState.selectedBattle?
                .difficulty ?? 1
        )
        let difficultyStep = min(
            maximumEnemyDifficultyStep,
            max(0, difficulty - 1)
        )
        let waveScale = pow(
            1.015 + min(difficulty, 30) * 0.001,
            Double(index)
        )
        let bossScale =
            ((raidConfiguration != nil || gameState.selectedBattle?.boss != nil)
                && index == battleEnemies.count - 1) ? 1.2 : 1.0
        let difficultyHPScale = pow(enemyHPGrowthPerDifficulty, difficultyStep)
        let difficultyAttackScale = pow(
            enemyAttackGrowthPerDifficulty,
            difficultyStep
        )
        let scaledHP =
            base.hp * CGFloat(difficultyHPScale * waveScale * bossScale)
        let resolvedHP =
            raidConfiguration == nil
            ? max(scaledHP, minimumEnemyHP(for: index))
            : scaledHP

        return CharacterStats(
            name: base.name,
            image: base.image,
            model: base.model,
            battleModel: base.battleModel,
            texture: base.texture,
            materialColor: base.materialColor,
            emissionColor: base.emissionColor,
            emissionIntensity: base.emissionIntensity,
            roughness: base.roughness,
            metalness: base.metalness,
            auraColor: base.auraColor,
            auraIntensity: base.auraIntensity,
            auraRadius: base.auraRadius,
            particleEffect: base.particleEffect,
            shadowColor: base.shadowColor,
            shadowOpacity: base.shadowOpacity,
            element: base.element,
            hp: resolvedHP,
            attack: base.attack
                * CGFloat(
                    difficultyAttackScale * pow(1.025, Double(index))
                        * bossScale
                ),
            attackSpeed: base.attackSpeed
        )
    }

    private func minimumEnemyHP(for index: Int) -> CGFloat {
        let requiredHits =
            isBossEnemy(at: index)
            ? minimumBossEnemyHits : minimumNormalEnemyHits
        let difficulty = Double(gameState.selectedBattle?.difficulty ?? 1)
        let difficultyStep = min(
            maximumEnemyDifficultyStep,
            max(0, difficulty - 1)
        )
        let difficultyScale = pow(
            enemyMinimumHPGrowthPerDifficulty,
            difficultyStep
        )
        let baselinePlayerHit = max(1, player.attack)

        return max(
            1,
            baselinePlayerHit * requiredHits * CGFloat(difficultyScale)
        )
    }

    private func startAutoAttack() {
        stopAutoAttack()
        guard isAuto else { return }

        autoTask = Task { @MainActor in
            while !Task.isCancelled {
                if !isAuto || showVictory || showDefeat { return }
                if currentTurn == .player && !isResolvingTurn {
                    attack(
                        with: activeCards.first {
                            playerMana >= Double($0.resolvedManaCost)
                        }
                    )
                }
                guard
                    await waitForActionCooldown(
                        for: leveledPlayer,
                        baseDuration: 0.5
                    )
                else {
                    return
                }
            }
        }
    }

    private func stopAutoAttack() {
        autoTask?.cancel()
        autoTask = nil
    }

    private func resumeAutoAttackIfPossible() {
        guard isAuto else { return }
        guard currentTurn == .player else { return }
        guard !isResolvingTurn else { return }
        guard !showVictory && !showDefeat else { return }
        guard !didTriggerTutorialRetreat else { return }
        guard multiplayerManager.raidCountdownRemaining == nil else { return }

        if autoTask == nil || autoTask?.isCancelled == true {
            startAutoAttack()
        }
    }

    private func nextComboStep(for input: String) -> BattleComboStepDefinition {
        let combos = loadBattleComboDefinitions()
        let proposedInputs = currentComboInputs + [input]
        let matchedCombo =
            comboMatching(inputs: proposedInputs, in: combos)
            ?? comboMatching(inputs: [input], in: combos)
            ?? combos.first { $0.isDefault == true }
            ?? combos.first

        let resolvedInputs =
            matchedCombo?.resolvedInputSequence.starts(with: proposedInputs)
            == true
            ? proposedInputs : [input]

        currentComboInputs = resolvedInputs
        activeComboID = matchedCombo?.id

        let steps = matchedCombo?.steps ?? battleCombo.steps
        guard !steps.isEmpty else {
            return BattleComboStepDefinition(
                id: "dash",
                input: "tap",
                label: "Dash",
                style: BattleComboStyle.dash.rawValue,
                damageMultiplier: 1.0,
                hitDelay: 0.22,
                holdDuration: 0.25,
                slowMotion: false,
                particleEffect: nil
            )
        }

        let stepIndex = min(max(0, resolvedInputs.count - 1), steps.count - 1)
        let step = steps[stepIndex]
        currentComboStepIndex = min(stepIndex + 1, steps.count)
        return step
    }

    private func comboMatching(
        inputs: [String],
        in combos: [BattleComboDefinition]
    ) -> BattleComboDefinition? {
        combos.first { combo in
            combo.resolvedInputSequence.starts(with: inputs)
        }
    }

    private func shouldContinueCombo(after step: BattleComboStepDefinition)
        -> Bool
    {
        guard raidConfiguration == nil else { return false }
        guard !battleCombo.steps.isEmpty else { return false }
        guard currentComboStepIndex < battleCombo.steps.count else {
            return false
        }
        return !step.isSlowMotion
    }

    private func scheduleComboWindowTimeout() {
        comboWindowTask?.cancel()
        let windowMilliseconds = max(
            250,
            Int((battleCombo.resolvedComboWindow * 1000).rounded())
        )
        comboWindowTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(windowMilliseconds))
            guard !Task.isCancelled else { return }
            guard currentTurn == .player else { return }
            guard !isResolvingTurn else { return }
            guard !showVictory && !showDefeat else { return }

            resetComboChain()
            currentTurn = .enemy
            await runEnemyTurn()
            isResolvingTurn = false
        }
    }

    private func resetComboChain() {
        comboWindowTask?.cancel()
        comboWindowTask = nil
        currentComboStepIndex = 0
        currentComboStep = nil
        currentComboInputs = []
        activeComboID = nil
    }

    private func setAutoMode(_ enabled: Bool) {
        isAuto = enabled
        savedAutoMode = enabled
    }

    @MainActor
    private func runEnemyTurn() async {
        let attackers = aliveEnemyIndices
        guard !attackers.isEmpty else {
            recoverMana(turnManaGain)
            currentTurn = .player
            return
        }

        for index in attackers {
            guard currentTurn == .enemy, !showVictory, !showDefeat else {
                return
            }
            guard enemyHPs.indices.contains(index), enemyHPs[index] > 0 else {
                continue
            }

            attackingEnemyIndex = index
            enemyAttackID += 1

            try? await Task.sleep(
                for: .milliseconds(
                    speedAdjustedMilliseconds(actionFrameCommitMilliseconds)
                )
            )
            guard !Task.isCancelled else { return }

            let enemyDamage = activeEnemies[index].attack / leveledPlayer.hp
            let rawEnemyDamage = max(
                1,
                Int(activeEnemies[index].attack.rounded())
            )
            withAnimation(.easeOut(duration: 0.2)) {
                playerHP -= enemyDamage
            }
            onRaidCombatLog?(
                "\(activeEnemies[index].name) verursacht \(rawEnemyDamage) Schaden."
            )

            if playerHP <= 0 {
                playerHP = 0
                isAuto = false
                autoTask?.cancel()
                manaRegenTask?.cancel()
                attackingEnemyIndex = nil
                showDefeat = true
                onRaidFinished?(false)
                return
            }

            guard
                await waitForActionCooldown(
                    for: activeEnemies[index],
                    baseDuration: 0.42
                )
            else {
                return
            }
            attackingEnemyIndex = nil
        }

        attackingEnemyIndex = nil
        recoverMana(turnManaGain)
        currentTurn = .player
        resumeAutoAttackIfPossible()
    }

    private func attack(
        with card: AbilityCardDefinition?,
        input: String = "tap"
    ) {
        guard currentTurn == .player else { return }
        guard !isResolvingTurn else { return }
        guard !showVictory && !showDefeat else { return }
        guard !didTriggerTutorialRetreat else { return }
        guard multiplayerManager.raidCountdownRemaining == nil else { return }

        comboWindowTask?.cancel()
        turnTask?.cancel()
        turnTask = Task { @MainActor in
            await resolvePlayerTurn(with: card, input: input)
        }
    }

    @MainActor
    private func resolvePlayerTurn(
        with card: AbilityCardDefinition?,
        input: String
    ) async {
        guard currentTurn == .player else { return }
        guard !isResolvingTurn else { return }
        guard !showVictory && !showDefeat else { return }
        guard !didTriggerTutorialRetreat else { return }

        let targetIndex = safeSelectedEnemyIndex
        guard enemyHPs.indices.contains(targetIndex), enemyHPs[targetIndex] > 0
        else {
            selectNextTarget()
            return
        }

        if let card {
            let cost = Double(card.resolvedManaCost)
            guard playerMana >= cost else { return }
            playerMana -= cost
        } else {
            recoverMana(baseAttackManaGain)
        }

        let comboStep = nextComboStep(for: input)
        isResolvingTurn = true
        currentComboStep = comboStep
        currentParticleEffect = comboStep.particleEffect ?? card?.particleEffect
        currentParticleTargetIndices = targetIndices(for: card)
        playerAttackID += 1

        let targetIndices = currentParticleTargetIndices
        if raidConfiguration != nil {
            currentTurn = .enemy
            submitRaidAttack(card: card, targetIndices: targetIndices)
            isResolvingTurn = false
            return
        }

        try? await Task.sleep(
            for: .milliseconds(
                speedAdjustedMilliseconds(actionFrameCommitMilliseconds)
            )
        )
        guard !Task.isCancelled else { return }

        let defeatedIndices = applyAttackDamage(
            with: card,
            targetIndices: targetIndices,
            comboStep: comboStep
        )

        guard
            await waitForActionCooldown(
                for: leveledPlayer,
                baseDuration: 0.42
            )
        else {
            return
        }

        if let tutorialConfig,
            tutorialConfig.retreatEnemyIndex == targetIndex,
            let threshold = tutorialConfig.enemyRetreatThreshold,
            enemyHPs[targetIndex] > 0,
            enemyHPs[targetIndex] <= threshold
        {
            triggerTutorialRetreat(using: tutorialConfig)
            isResolvingTurn = false
            return
        }

        if !defeatedIndices.isEmpty {
            defeatEnemies(at: defeatedIndices)
            if showVictory || didTriggerTutorialRetreat {
                isResolvingTurn = false
                return
            }
        }

        guard !showVictory && !showDefeat else {
            isResolvingTurn = false
            return
        }

        currentParticleEffect = nil
        currentParticleTargetIndices = []
        currentComboStep = nil
        if shouldContinueCombo(after: comboStep) {
            isResolvingTurn = false
            scheduleComboWindowTimeout()
            resumeAutoAttackIfPossible()
            return
        }

        resetComboChain()
        currentTurn = .enemy
        await runEnemyTurn()
        isResolvingTurn = false
    }

    private func submitRaidAttack(
        card: AbilityCardDefinition?,
        targetIndices: [Int]
    ) {
        guard let targetIndex = targetIndices.first,
            activeEnemies.indices.contains(targetIndex)
        else {
            currentParticleTargetIndices = []
            currentTurn = .player
            return
        }

        let actionName = card?.name ?? "Basisangriff"
        let proposedDamage = calculateRaidDamage(
            for: card,
            targetIndex: targetIndex
        )
        multiplayerManager.submitRaidPlayerAction(
            actionName: actionName,
            proposedDamage: proposedDamage
        )
    }

    private func triggerTutorialRetreat(using config: BattleTutorialConfig) {
        guard !didTriggerTutorialRetreat else { return }
        didTriggerTutorialRetreat = true
        isAuto = false
        autoTask?.cancel()
        turnTask?.cancel()
        manaRegenTask?.cancel()
        attackingEnemyIndex = nil
        currentParticleEffect = nil
        currentParticleTargetIndices = []
        isResolvingTurn = false
        config.onEnemyRetreat()
    }

    private func applyAttackDamage(
        with card: AbilityCardDefinition?,
        targetIndices: [Int],
        comboStep: BattleComboStepDefinition
    ) -> [Int] {
        var defeatedIndices: [Int] = []

        withAnimation(.easeOut(duration: 0.2)) {
            for index in targetIndices where enemyHPs.indices.contains(index) {
                guard enemyHPs[index] > 0 else { continue }

                let multiplier = CGFloat(
                    card.map {
                        effectiveCardMultiplier($0)
                            * elementalMultiplier(for: $0, enemyIndex: index)
                    } ?? 1.0
                )
                let damage =
                    (leveledPlayer.attack * multiplier
                        * CGFloat(comboStep.resolvedDamageMultiplier))
                    / activeEnemies[index].hp
                enemyHPs[index] -= damage

                if enemyHPs[index] <= 0 {
                    enemyHPs[index] = 0
                    defeatedIndices.append(index)
                }
            }
        }

        return defeatedIndices.sorted()
    }

    private func defeatEnemies(at indices: [Int]) {
        let uniqueSortedIndices = Array(Set(indices)).sorted()
        guard !uniqueSortedIndices.isEmpty else { return }

        if aliveEnemyIndices.isEmpty {
            if let tutorialConfig {
                isAuto = false
                autoTask?.cancel()
                turnTask?.cancel()
                manaRegenTask?.cancel()
                resetComboChain()
                attackingEnemyIndex = nil
                currentParticleEffect = nil
                currentParticleTargetIndices = []
                isResolvingTurn = false
                tutorialConfig.onBattleComplete()
                return
            }

            awardVictoryRewardsIfNeeded()
            isAuto = false
            autoTask?.cancel()
            turnTask?.cancel()
            manaRegenTask?.cancel()
            resetComboChain()
            attackingEnemyIndex = nil
            currentParticleTargetIndices = []
            isResolvingTurn = false
            onRaidFinished?(true)
            showVictory = true
            return
        }

        let lastIndex = uniqueSortedIndices.max() ?? safeSelectedEnemyIndex
        selectNextTarget(after: lastIndex)
        currentParticleEffect = nil
        currentParticleTargetIndices = []
    }

    private func awardVictoryRewardsIfNeeded() {
        guard !didAwardRewards else { return }
        didAwardRewards = true
        levelBeforeVictory = playerLevel
        awardedXP = battleXPReward
        let accountProgressBefore = PlayerInventoryStore.accountProgress(
            in: modelContext
        )
        ascendedLevelBeforeVictory = accountProgressBefore.level
        awardedAscendedXP = awardedXP
        awardedRewards = PlayerInventoryStore.addBattleRewards(
            raidConfiguration?.rewards ?? gameState.activeBattleRewards,
            in: modelContext,
            characterID: player.model,
            limits: gameState.selectedBattle?.dailyRewardLimits
        )
        awardedCharacterRewards =
            gameState.selectedBattle?.characterRewards ?? []
        for characterReward in awardedCharacterRewards {
            PlayerInventoryStore.addOwned(
                characterID: characterReward.characterID,
                in: modelContext
            )
        }
        awardedSkinRewards = gameState.selectedBattle?.skinRewards ?? []
        for skinReward in awardedSkinRewards {
            PlayerInventoryStore.addOwnedSkin(
                characterID: skinReward.characterID,
                skinID: skinReward.skinID,
                in: modelContext
            )
        }
        awardedCardRewards =
            raidConfiguration?.cardRewards ?? gameState.selectedBattle?
            .cardRewards ?? []
        for cardReward in awardedCardRewards where cardReward.amount > 0 {
            let boostedAmount = max(
                cardReward.amount,
                Int(
                    (Double(cardReward.amount)
                        * max(0.1, 1 + skillBonuses.dropPercent(for: "cards")))
                        .rounded()
                )
            )
            PlayerInventoryStore.addOwnedCard(
                cardID: cardReward.cardID,
                amount: boostedAmount,
                in: modelContext
            )
        }
        let progress = PlayerInventoryStore.addXP(
            awardedXP,
            to: player.model,
            in: modelContext
        )
        if let raidParticipants = multiplayerManager.activeRaid?.participants {
            let raidCharacterModels = Set(
                raidParticipants.compactMap(\.characterModel)
            )
            for model in raidCharacterModels where model != player.model {
                _ = PlayerInventoryStore.addXP(
                    awardedXP,
                    to: model,
                    in: modelContext
                )
            }
        }
        let accountProgressAfter = PlayerInventoryStore.addAccountXP(
            awardedAscendedXP,
            in: modelContext
        )
        levelAfterVictory = progress.level
        ascendedLevelAfterVictory = accountProgressAfter.level
        PlayerInventoryStore.recordBattleVictory(
            defeatedEnemyCount: battleEnemies.count,
            in: modelContext
        )

        if let battleID = gameState.selectedBattle?.id {
            PlayerInventoryStore.markBattleCompleted(battleID, in: modelContext)
        }
    }

    private func calculateRaidDamage(
        for card: AbilityCardDefinition?,
        targetIndex: Int
    ) -> Int {
        let multiplier = CGFloat(
            card.map {
                effectiveCardMultiplier($0)
                    * elementalMultiplier(for: $0, enemyIndex: targetIndex)
            } ?? 1.0
        )
        return max(1, Int((leveledPlayer.attack * multiplier).rounded()))
    }

    private func raidCountdownOverlay(seconds: Int, bossName: String)
        -> some View
    {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("RAID STARTET")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.yellow)

                Text("\(seconds)")
                    .font(.system(size: 68, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(bossName) bereitet sich vor.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(
                Color.black.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
        }
    }

    private var isLocalRaidTargeted: Bool {
        guard let raidConfiguration else { return false }
        return multiplayerManager.activeRaid?.bossTargetParticipantID
            == raidConfiguration.localParticipantID
    }

    private func applyResolvedRaidActionIfNeeded() {
        guard let raidConfiguration else { return }
        guard let resolvedAction = multiplayerManager.latestResolvedRaidAction
        else {
            return
        }
        guard resolvedAction.sessionID == raidConfiguration.sessionID else {
            return
        }
        guard enemyHPs.indices.contains(0) else { return }

        currentParticleEffect = nil
        currentParticleTargetIndices = []
        if resolvedAction.actorID != raidConfiguration.localParticipantID {
            allyAttackerParticipantID = resolvedAction.actorID
            allyAttackID += 1
        }
        onRaidBossHPChanged?(resolvedAction.resultingBossHP)
        onRaidCombatLog?(
            "\(resolvedAction.actorName) nutzt \(resolvedAction.actionName). Boss-HP: \(resolvedAction.resultingBossHP)"
        )

        withAnimation(.easeOut(duration: 0.2)) {
            enemyHPs[0] =
                CGFloat(resolvedAction.resultingBossHP)
                / max(activeEnemies[0].hp, 1)
        }

        if resolvedAction.victory {
            awardVictoryRewardsIfNeeded()
            isAuto = false
            autoTask?.cancel()
            manaRegenTask?.cancel()
            attackingEnemyIndex = nil
            onRaidFinished?(true)
            showVictory = true
            return
        }
    }

    private func applyResolvedRaidBossAttackIfNeeded() {
        guard let raidConfiguration else { return }
        guard
            let resolvedAttack = multiplayerManager.latestResolvedRaidBossAttack
        else {
            return
        }
        guard resolvedAttack.sessionID == raidConfiguration.sessionID else {
            return
        }
        guard
            resolvedAttack.targetParticipantID
                == raidConfiguration.localParticipantID
        else {
            currentTurn = .player
            return
        }

        let normalizedHP =
            CGFloat(resolvedAttack.resultingHP)
            / max(CGFloat(raidConfiguration.localParticipantMaxHP), 1)
        attackingEnemyIndex = 0
        enemyAttackID += 1

        turnTask?.cancel()
        turnTask = Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(actionFrameCommitMilliseconds)
            )
            guard !Task.isCancelled else { return }
            guard currentTurn == .enemy, !showVictory, !showDefeat else {
                return
            }
            withAnimation(.easeOut(duration: 0.2)) {
                playerHP = normalizedHP
            }

            if resolvedAttack.defeat || playerHP <= 0 {
                playerHP = 0
                isAuto = false
                autoTask?.cancel()
                manaRegenTask?.cancel()
                attackingEnemyIndex = nil
                showDefeat = true
                onRaidFinished?(false)
                return
            }

            guard
                await waitForActionCooldown(
                    for: activeEnemies[0],
                    baseDuration: 0.42
                )
            else {
                return
            }
            attackingEnemyIndex = nil
            recoverMana(turnManaGain)
            currentTurn = .player
            resumeAutoAttackIfPossible()
        }
    }
}

private struct CardBattleProgress {
    let level: Int
    let stars: Int
}
