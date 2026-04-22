//
//  BattleView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

enum Turn {
    case player
    case enemy
}

struct BattleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerDeckCardSlot.slotIndex) private var deckSlots:
        [PlayerDeckCardSlot]
    @Query(sort: \OwnedAbilityCard.cardID) private var ownedCards:
        [OwnedAbilityCard]
    @Query(sort: \PlayerCharacterProgress.characterID) private
        var characterProgress: [PlayerCharacterProgress]

    let player: CharacterStats
    let enemy: CharacterStats
    let onExit: () -> Void

    @State private var currentTurn: Turn = .player
    @State private var playerHP: CGFloat = 1
    @State private var enemyHPs: [CGFloat] = []
    @State private var selectedEnemyIndex = 0
    @State private var showVictory = false
    @State private var showDefeat = false
    @State private var isAuto = false
    @State private var isFast = false
    @State private var playerAttackID = 0
    @State private var enemyAttackID = 0
    @State private var attackingEnemyIndex: Int?
    @State private var didAwardRewards = false
    @State private var currentParticleEffect: String?
    @State private var playerMana: Double = 60
    @State private var awardedXP = 0
    @State private var levelBeforeVictory = 1
    @State private var levelAfterVictory = 1
    @State private var autoTask: Task<Void, Never>?
    @State private var manaRegenTask: Task<Void, Never>?
    @State private var inspectedCard: AbilityCardDefinition?
    @State private var cardLongPressActive = false
    @State private var cardPressTask: Task<Void, Never>?

    private let maxMana: Double = 100
    private let baseAttackManaGain: Double = 18
    private let turnManaGain: Double = 12
    private let manaRegenPerTick: Double = 2
    private let manaRegenTickMilliseconds = 450

    private var activeCards: [AbilityCardDefinition] {
        deckSlots
            .sorted { $0.slotIndex < $1.slotIndex }
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

    private var leveledPlayer: CharacterStats {
        let hpScale = pow(1.12, Double(playerLevel - 1))
        let attackScale = pow(1.10, Double(playerLevel - 1))
        return CharacterStats(
            name: player.name,
            image: player.image,
            model: player.model,
            battleModel: player.battleModel,
            texture: player.texture,
            element: player.element,
            hp: player.hp * CGFloat(hpScale),
            attack: player.attack * CGFloat(attackScale)
        )
    }

    private var battleEnemies: [CharacterStats] {
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
        guard gameState.selectedBattle?.boss != nil else { return false }
        return safeSelectedEnemyIndex == activeEnemies.count - 1
    }

    private var battleXPReward: Int {
        if let xpReward = gameState.selectedBattle?.xpReward {
            return xpReward
        }
        let difficulty = gameState.selectedBattle?.difficulty ?? 1
        return 70 + difficulty * 35 + battleEnemies.count * 20
    }

    private var battleDelay: Double {
        isFast ? 0.45 : 0.85
    }

    var body: some View {
        ZStack {
            BattleSceneView(
                player: leveledPlayer,
                enemies: activeEnemies,
                enemyHPs: enemyHPs,
                selectedEnemyIndex: safeSelectedEnemyIndex,
                playerAttackID: playerAttackID,
                enemyAttackID: enemyAttackID,
                attackingEnemyIndex: attackingEnemyIndex,
                particleEffect: currentParticleEffect,
                particleEffects: gameState.particleEffects,
                groundTexture: gameState.activeGroundTexture,
                skyboxTexture: gameState.activeSkyboxTexture,
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
                .onTapGesture {
                    attack(with: nil)
                }

            battleHUD

            if showVictory {
                VictoryView(
                    currencies: loadCurrencyDefinitions(),
                    rewards: gameState.activeBattleRewards,
                    xpReward: awardedXP,
                    levelBefore: levelBeforeVictory,
                    levelAfter: levelAfterVictory,
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

            if let inspectedCard {
                cardInfoOverlay(for: inspectedCard)
                    .zIndex(25)
            }
        }
        .onAppear {
            playerHP = 1
            enemyHPs = Array(repeating: 1, count: activeEnemies.count)
            playerMana = 60
            selectedEnemyIndex = 0
            startManaRegen()
        }
        .onChange(of: isFast) {
            if isAuto {
                startAutoAttack()
            }
        }
        .onChange(of: isAuto) { _, enabled in
            if enabled && currentTurn == .player {
                startAutoAttack()
            } else if !enabled {
                autoTask?.cancel()
            }
        }
        .onDisappear {
            autoTask?.cancel()
            manaRegenTask?.cancel()
            cardPressTask?.cancel()
        }
    }

    private var battleHUD: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 14)
                .padding(.top, 14)

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    enemyHPPanel
                    targetStrip
                }
                .padding(.leading, 14)
                .padding(.top, 16)

                Spacer()

                cardRail
                    .padding(.trailing, 8)
                    .padding(.top, 74)
            }

            Spacer()

            HStack(alignment: .bottom) {
                playerHPPanel
                    .padding(.leading, 16)
                    .padding(.bottom, 18)

                Spacer()

                bottomControls
                    .padding(.trailing, 18)
                    .padding(.bottom, 20)
            }
        }
        .foregroundStyle(.white)
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
                isFast.toggle()
            } label: {
                Image(
                    systemName: isFast
                        ? "gauge.with.dots.needle.67percent"
                        : "gauge.with.dots.needle.33percent"
                )
                .font(.system(size: 16, weight: .black))
                .frame(width: 38, height: 30)
                .background(
                    isFast
                        ? Color.orange.opacity(0.86)
                        : Color.black.opacity(0.58),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)

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
            width: 250
        )
    }

    private var playerHPPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            battleHPBar(
                title: player.name.uppercased(),
                value: playerHP,
                maximumHP: leveledPlayer.hp,
                width: 220
            )

            HStack(spacing: 8) {
                Text("DMG \(Int(leveledPlayer.attack))")
                Text("HP \(Int(leveledPlayer.hp))")
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
                attack(with: card)
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
                isAuto.toggle()
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
        }
    }

    private var defeatOverlay: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "xmark.shield.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.red)

                VStack(spacing: 6) {
                    Text("DEFEAT")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.white)

                    Text("Dein Team wurde besiegt.")
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
                        Label("Home", systemImage: "house.fill")
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
        if UIImage(named: imageName) == nil {
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
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
        }
    }

    private func retryBattle() {
        playerHP = 1
        enemyHPs = Array(repeating: 1, count: activeEnemies.count)
        playerMana = 60
        selectedEnemyIndex = 0
        currentTurn = .player
        currentParticleEffect = nil
        attackingEnemyIndex = nil
        showDefeat = false
        startManaRegen()
    }

    private func returnHomeFromDefeat() {
        isAuto = false
        autoTask?.cancel()
        manaRegenTask?.cancel()
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
        return card.damageMultiplier * levelGrowth * starGrowth
    }

    private func elementalMultiplier(for card: AbilityCardDefinition) -> Double
    {
        GameElement(card.element).multiplier(
            against: GameElement(currentEnemy.element)
        )
    }

    private func recoverMana(_ amount: Double) {
        playerMana = min(maxMana, playerMana + amount)
    }

    private func startManaRegen() {
        manaRegenTask?.cancel()
        manaRegenTask = Task { @MainActor in
            while !Task.isCancelled {
                if showVictory || showDefeat { return }
                recoverMana(manaRegenPerTick)
                try? await Task.sleep(
                    for: .milliseconds(manaRegenTickMilliseconds)
                )
            }
        }
    }

    private func scaledEnemy(_ base: CharacterStats, at index: Int)
        -> CharacterStats
    {
        let difficulty = Double(gameState.selectedBattle?.difficulty ?? 1)
        let waveScale = pow(1.07 + difficulty * 0.01, Double(index))
        let bossScale =
            (gameState.selectedBattle?.boss != nil
                && index == battleEnemies.count - 1) ? 1.55 : 1.0
        return CharacterStats(
            name: base.name,
            image: base.image,
            model: base.model,
            battleModel: base.battleModel,
            texture: base.texture,
            element: base.element,
            hp: base.hp * CGFloat(waveScale * bossScale),
            attack: base.attack * CGFloat(pow(1.05, Double(index)) * bossScale)
        )
    }

    private func startAutoAttack() {
        autoTask?.cancel()
        autoTask = Task { @MainActor in
            while !Task.isCancelled {
                if !isAuto || showVictory || showDefeat { return }
                if currentTurn == .player {
                    attack(
                        with: activeCards.first {
                            playerMana >= Double($0.resolvedManaCost)
                        }
                    )
                }
                try? await Task.sleep(for: .milliseconds(isFast ? 550 : 1050))
            }
        }
    }

    private func enemyAttack() {
        guard currentTurn == .enemy else { return }
        currentParticleEffect = nil
        Task { @MainActor in
            await runEnemyTurn()
        }
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

            try? await Task.sleep(for: .milliseconds(isFast ? 220 : 360))

            let enemyDamage = activeEnemies[index].attack / leveledPlayer.hp
            withAnimation(.easeOut(duration: 0.2)) {
                playerHP -= enemyDamage
            }

            if playerHP <= 0 {
                playerHP = 0
                isAuto = false
                autoTask?.cancel()
                manaRegenTask?.cancel()
                attackingEnemyIndex = nil
                showDefeat = true
                return
            }

            try? await Task.sleep(for: .milliseconds(isFast ? 220 : 520))
        }

        attackingEnemyIndex = nil
        recoverMana(turnManaGain)
        currentTurn = .player
    }

    private func attack(with card: AbilityCardDefinition?) {
        guard currentTurn == .player else { return }
        guard !showVictory && !showDefeat else { return }

        if let card {
            let cost = Double(card.resolvedManaCost)
            guard playerMana >= cost else { return }
            playerMana -= cost
        } else {
            recoverMana(baseAttackManaGain)
        }

        currentTurn = .enemy
        currentParticleEffect = card?.particleEffect
        playerAttackID += 1

        let targetIndex = safeSelectedEnemyIndex
        guard enemyHPs.indices.contains(targetIndex), enemyHPs[targetIndex] > 0
        else {
            selectNextTarget()
            currentTurn = .player
            return
        }

        let multiplier = CGFloat(
            card.map {
                effectiveCardMultiplier($0) * elementalMultiplier(for: $0)
            } ?? 1.0
        )
        let playerDamage = (leveledPlayer.attack * multiplier) / currentEnemy.hp
        withAnimation(.easeOut(duration: 0.2)) {
            enemyHPs[targetIndex] -= playerDamage
        }

        if enemyHPs[targetIndex] <= 0 {
            enemyHPs[targetIndex] = 0
            defeatCurrentEnemy(at: targetIndex)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + battleDelay) {
            enemyAttack()
        }
    }

    private func defeatCurrentEnemy(at index: Int) {
        if aliveEnemyIndices.isEmpty {
            awardVictoryRewardsIfNeeded()
            isAuto = false
            autoTask?.cancel()
            manaRegenTask?.cancel()
            attackingEnemyIndex = nil
            showVictory = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            selectNextTarget(after: index)
            currentParticleEffect = nil
            enemyAttack()
        }
    }

    private func awardVictoryRewardsIfNeeded() {
        guard !didAwardRewards else { return }
        didAwardRewards = true
        levelBeforeVictory = playerLevel
        awardedXP = battleXPReward

        PlayerInventoryStore.add(
            gameState.activeBattleRewards,
            in: modelContext
        )
        let progress = PlayerInventoryStore.addXP(
            awardedXP,
            to: player.model,
            in: modelContext
        )
        _ = PlayerInventoryStore.addAccountXP(awardedXP, in: modelContext)
        levelAfterVictory = progress.level

        if let battleID = gameState.selectedBattle?.id {
            PlayerInventoryStore.markBattleCompleted(battleID, in: modelContext)
        }
    }
}

private struct CardBattleProgress {
    let level: Int
    let stars: Int
}

#Preview {
    let samplePlayer = CharacterStats(
        name: "Zaron",
        image: "",
        model: "zaron",
        hp: 100,
        attack: 20
    )
    let sampleEnemy = CharacterStats(
        name: "Shela",
        image: "",
        model: "shela",
        hp: 80,
        attack: 12
    )

    BattleView(
        player: samplePlayer,
        enemy: sampleEnemy,
        onExit: {}
    )
    .environmentObject(GameState())
    .environmentObject(ThemeManager())
}
