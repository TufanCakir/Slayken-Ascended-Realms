//
//  BattleView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

enum Turn {
    case player
    case enemy
}

struct BattleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState

    let player: CharacterStats
    let enemy: CharacterStats
    let onExit: () -> Void

    @State private var currentTurn: Turn = .player
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
                Text(currentTurn == .player ? "YOUR TURN" : "ENEMY TURN")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(
                        currentTurn == .player ? Color.green : Color.red
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())

                Spacer()
            }

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    if currentTurn == .player {
                        attack()
                    }
                }

            VStack {
                battleHPBar(
                    title: enemy.name.uppercased(),
                    value: enemyHP,
                    maximumHP: enemy.hp,
                    alignment: .top
                )
                .padding(.horizontal, 24)
                .padding(.top, 44)

                Spacer()

                VStack(spacing: 16) {
                    HStack {
                        Button {
                            isFast.toggle()
                        } label: {
                            Text("Speed x2")
                                .font(.system(size: 12, weight: .bold))
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
                            if isAuto && currentTurn == .player {
                                attack()
                            }
                        } label: {
                            Text("AUTO")
                                .font(.system(size: 12, weight: .bold))
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

                    battleHPBar(
                        title: player.name.uppercased(),
                        value: playerHP,
                        maximumHP: player.hp,
                        alignment: .bottom
                    )
                }
                .padding(.horizontal, 24)
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

    @ViewBuilder
    func battleHPBar(
        title: String,
        value: CGFloat,
        maximumHP: CGFloat,
        alignment: VerticalEdge
    ) -> some View {
        let safe = max(0, min(1, value))
        let currentHP = max(0, Int((maximumHP * safe).rounded()))
        let goldTop = Color(red: 0.90, green: 0.79, blue: 0.48)
        let goldBottom = Color(red: 0.42, green: 0.28, blue: 0.11)

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Text("HP")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.82, green: 0.95, blue: 0.74))

                Text("\(currentHP)/\(Int(maximumHP))")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.92),
                                    Color(red: 0.16, green: 0.17, blue: 0.18),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.19, green: 0.64, blue: 0.14),
                                    Color(red: 0.43, green: 0.86, blue: 0.19),
                                    Color(red: 0.11, green: 0.46, blue: 0.09),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(
                                cornerRadius: 7,
                                style: .continuous
                            )
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.34),
                                        .clear,
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 7)
                        }
                        .frame(width: max(18, (geo.size.width - 8) * safe))
                        .padding(4)
                        .animation(.easeInOut(duration: 0.25), value: safe)

                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [goldTop, goldBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )

                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        .padding(2)
                }
            }
            .frame(height: 22)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.82),
                    Color(red: 0.11, green: 0.12, blue: 0.14).opacity(0.94),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [goldTop, goldBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
        .frame(
            maxWidth: alignment == .top ? 300 : .infinity,
            alignment: .leading
        )
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

    func enemyAttack() {
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
                return
            }

            // Back to player
            currentTurn = .player
        }
    }

    func attack() {
        guard currentTurn == .player else { return }
        guard !showVictory && !showDefeat else { return }

        currentTurn = .enemy

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

        // Enemy Turn Delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            enemyAttack()
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
