//
//  BattleView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct BattleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState

    let player: CharacterStats
    let enemy: CharacterStats
    let onExit: () -> Void

    @State private var playerHP: CGFloat = 1
    @State private var enemyHP: CGFloat = 1
    @State private var showVictory = false
    @State private var showDefeat = false
    @State private var enemyHit = false
    @State private var playerHit = false
    @State private var isAuto = false
    @State private var isFast = false

    var body: some View {
        ZStack {
            BattleSceneView(
                player: player,
                enemy: enemy,
                enemyHP: enemyHP,
                groundTexture: gameState.selectedMap.mapImage,
                skyboxTexture: gameState.selectedBackground.image
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    HStack {
                        Button {
                            isFast.toggle()
                        } label: {
                            Text("Speed x2")
                                .font(.system(size: 14, weight: .bold))
                                .padding()
                                .background(
                                    isFast
                                        ? (theme.selectedTheme?.secondary.color
                                            ?? .orange)
                                        : Color.black
                                )
                                .clipShape(.capsule)
                        }

                        Button {
                            isAuto.toggle()
                            if isAuto {
                                startAutoAttack()
                            }
                        } label: {
                            Text("AUTO")
                                .font(.system(size: 14, weight: .bold))
                                .padding()
                                .background(
                                    isAuto
                                        ? (theme.selectedTheme?.primary.color
                                            ?? .blue)
                                        : Color.black
                                )
                                .clipShape(.capsule)
                        }
                    }
                    .foregroundStyle(.white)

                    hpBar(value: playerHP)
                        .frame(height: 14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            if showVictory {
                VictoryView {
                    onExit()
                }
            }

            if showDefeat {
                Text("DEFEAT")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color ?? .red,
                                theme.selectedTheme?.secondary.color ?? .orange,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: (theme.selectedTheme?.glow.color ?? .red)
                            .opacity(0.8),
                        radius: 15
                    )
            }
        }
        .onTapGesture {
            attack()
        }
        .onAppear {
            playerHP = 1
            enemyHP = 1
        }
        .onChange(of: isFast) {
            if isAuto {
                startAutoAttack()
            }
        }
    }

    func startAutoAttack() {
        Timer.scheduledTimer(
            withTimeInterval: isFast ? 0.5 : 1.0,
            repeats: true
        ) { timer in
            if !isAuto || showVictory || showDefeat {
                timer.invalidate()
                return
            }
            attack()
        }
    }

    func hpBar(value: CGFloat) -> some View {
        GeometryReader { geo in
            let safe = max(0, min(1, value))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.5))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color ?? .red,
                                theme.selectedTheme?.secondary.color ?? .orange,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * safe)
                    .animation(.easeInOut(duration: 0.25), value: safe)

                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)

                HStack {
                    Spacer()
                    Text("\(Int(safe * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                    Spacer()
                }
            }
        }
        .frame(height: 12)
    }

    func attack() {
        guard !showVictory && !showDefeat else { return }

        playerHit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            playerHit = false
        }

        let playerDamage = player.attack / enemy.hp
        withAnimation(.easeOut(duration: 0.2)) {
            enemyHP -= playerDamage
        }

        if enemyHP <= 0 {
            enemyHP = 0
            showVictory = true
            return
        }

        enemyHit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            enemyHit = false

            let enemyDamage = enemy.attack / player.hp
            withAnimation(.easeOut(duration: 0.2)) {
                playerHP -= enemyDamage
            }

            if playerHP <= 0 {
                playerHP = 0
                showDefeat = true
            }
        }
    }
}

#Preview {
    let samplePlayer = CharacterStats(
        name: "Hero",
        image: "acsended_riven",
        model: "warrior",
        hp: 100,
        attack: 20
    )
    let sampleEnemy = CharacterStats(
        name: "Goblin",
        image: "sar_dragon",
        model: "warrior",
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
