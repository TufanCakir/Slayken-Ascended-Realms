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
    @Query(sort: \PlayerDeckCardSlot.slotIndex) private var deckSlots: [PlayerDeckCardSlot]
    @Query(sort: \PlayerCharacterProgress.characterID) private var characterProgress: [PlayerCharacterProgress]

    let player: CharacterStats
    let enemy: CharacterStats
    let onExit: () -> Void

    @State private var currentTurn: Turn = .player
    @State private var playerHP: CGFloat = 1
    @State private var enemyHP: CGFloat = 1
    @State private var currentEnemyIndex = 0
    @State private var showVictory = false
    @State private var showDefeat = false
    @State private var isAuto = false
    @State private var isFast = false
    @State private var playerAttackID = 0
    @State private var enemyAttackID = 0
    @State private var didAwardRewards = false
    @State private var currentParticleEffect: String?
    @State private var awardedXP = 0
    @State private var levelBeforeVictory = 1
    @State private var levelAfterVictory = 1
    @State private var autoTask: Task<Void, Never>?

    private var activeCards: [AbilityCardDefinition] {
        deckSlots
            .sorted { $0.slotIndex < $1.slotIndex }
            .compactMap { slot in gameState.abilityCards.first { $0.id == slot.cardID } }
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
            hp: player.hp * CGFloat(hpScale),
            attack: player.attack * CGFloat(attackScale)
        )
    }

    private var battleEnemies: [CharacterStats] {
        var wave = gameState.selectedBattle?.enemies?.isEmpty == false
            ? gameState.selectedBattle?.enemies ?? []
            : [enemy]

        if let boss = gameState.selectedBattle?.boss {
            wave.append(boss)
        }

        return wave.isEmpty ? [enemy] : wave
    }

    private var currentEnemy: CharacterStats {
        let index = min(currentEnemyIndex, battleEnemies.count - 1)
        return scaledEnemy(battleEnemies[index], at: index)
    }

    private var isBossWave: Bool {
        guard gameState.selectedBattle?.boss != nil else { return false }
        return currentEnemyIndex == battleEnemies.count - 1
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
                enemy: currentEnemy,
                enemyHP: enemyHP,
                playerAttackID: playerAttackID,
                enemyAttackID: enemyAttackID,
                particleEffect: currentParticleEffect,
                groundTexture: gameState.activeGroundTexture,
                skyboxTexture: gameState.activeSkyboxTexture
            )
            .id("\(currentEnemy.id)-\(currentEnemyIndex)-\(playerLevel)")
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
        }
        .onAppear {
            playerHP = 1
            enemyHP = 1
            currentEnemyIndex = 0
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
                    waveStrip
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
                Image(systemName: isFast ? "gauge.with.dots.needle.67percent" : "gauge.with.dots.needle.33percent")
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 38, height: 30)
                    .background(isFast ? Color.orange.opacity(0.86) : Color.black.opacity(0.58), in: Capsule())
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

    private var enemyHPPanel: some View {
        battleHPBar(
            title: isBossWave ? "BOSS  \(currentEnemy.name.uppercased())" : currentEnemy.name.uppercased(),
            value: enemyHP,
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
            }
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var waveStrip: some View {
        HStack(spacing: 4) {
            ForEach(battleEnemies.indices, id: \.self) { index in
                Circle()
                    .fill(index < currentEnemyIndex ? Color.green : index == currentEnemyIndex ? Color.red : Color.white.opacity(0.38))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(.black.opacity(0.55), lineWidth: 1))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.42), in: Capsule())
    }

    private var cardRail: some View {
        VStack(spacing: 8) {
            ForEach(activeCards.prefix(5)) { card in
                Button {
                    attack(with: card)
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        cardImage(card.image)
                            .frame(width: 58, height: 78)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.65), lineWidth: 1))

                        Text("x\(String(format: "%.1f", card.damageMultiplier))")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.72), in: Capsule())
                            .padding(3)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bottomControls: some View {
        HStack(spacing: 8) {
            Button {
                currentTurn = .player
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "scope")
                        .font(.system(size: 15, weight: .black))
                    Text("TARGET")
                        .font(.system(size: 7, weight: .black))
                }
                .frame(width: 58, height: 42)
                .background(Color.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
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
                .background(isAuto ? Color.green.opacity(0.75) : Color.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var defeatOverlay: some View {
        VStack(spacing: 14) {
            Text("DEFEAT")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.red)
            Button("Retry") {
                playerHP = 1
                enemyHP = 1
                currentEnemyIndex = 0
                currentTurn = .player
                showDefeat = false
            }
            .font(.system(size: 16, weight: .black))
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(.white, in: Capsule())
            .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.68).ignoresSafeArea())
    }

    private func battleHPBar(title: String, value: CGFloat, maximumHP: CGFloat, width: CGFloat) -> some View {
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
                        .fill(LinearGradient(colors: [.green, .mint, .green.opacity(0.65)], startPoint: .leading, endPoint: .trailing))
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
        .background(Color.black.opacity(0.50), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    @ViewBuilder
    private func cardImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) == nil {
            ZStack {
                LinearGradient(colors: [.black.opacity(0.86), .blue.opacity(0.55)], startPoint: .top, endPoint: .bottom)
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

    private func scaledEnemy(_ base: CharacterStats, at index: Int) -> CharacterStats {
        let difficulty = Double(gameState.selectedBattle?.difficulty ?? 1)
        let waveScale = pow(1.07 + difficulty * 0.01, Double(index))
        let bossScale = (gameState.selectedBattle?.boss != nil && index == battleEnemies.count - 1) ? 1.55 : 1.0
        return CharacterStats(
            name: base.name,
            image: base.image,
            model: base.model,
            battleModel: base.battleModel,
            texture: base.texture,
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
                    attack(with: activeCards.first)
                }
                try? await Task.sleep(for: .milliseconds(isFast ? 550 : 1050))
            }
        }
    }

    private func enemyAttack() {
        guard currentTurn == .enemy else { return }
        currentParticleEffect = nil
        enemyAttackID += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            let enemyDamage = currentEnemy.attack / leveledPlayer.hp
            withAnimation(.easeOut(duration: 0.2)) {
                playerHP -= enemyDamage
            }

            if playerHP <= 0 {
                playerHP = 0
                isAuto = false
                autoTask?.cancel()
                showDefeat = true
                return
            }

            currentTurn = .player
        }
    }

    private func attack(with card: AbilityCardDefinition?) {
        guard currentTurn == .player else { return }
        guard !showVictory && !showDefeat else { return }

        currentTurn = .enemy
        currentParticleEffect = card?.particleEffect
        playerAttackID += 1

        let multiplier = CGFloat(card?.damageMultiplier ?? 1.0)
        let playerDamage = (leveledPlayer.attack * multiplier) / currentEnemy.hp
        withAnimation(.easeOut(duration: 0.2)) {
            enemyHP -= playerDamage
        }

        if enemyHP <= 0 {
            enemyHP = 0
            defeatCurrentEnemy()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + battleDelay) {
            enemyAttack()
        }
    }

    private func defeatCurrentEnemy() {
        if currentEnemyIndex < battleEnemies.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                currentEnemyIndex += 1
                enemyHP = 1
                currentTurn = .player
                currentParticleEffect = nil
            }
        } else {
            awardVictoryRewardsIfNeeded()
            isAuto = false
            autoTask?.cancel()
            showVictory = true
        }
    }

    private func awardVictoryRewardsIfNeeded() {
        guard !didAwardRewards else { return }
        didAwardRewards = true
        levelBeforeVictory = playerLevel
        awardedXP = battleXPReward

        PlayerInventoryStore.add(gameState.activeBattleRewards, in: modelContext)
        let progress = PlayerInventoryStore.addXP(awardedXP, to: player.model, in: modelContext)
        levelAfterVictory = progress.level

        if let battleID = gameState.selectedBattle?.id {
            PlayerInventoryStore.markBattleCompleted(battleID, in: modelContext)
        }
    }
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
