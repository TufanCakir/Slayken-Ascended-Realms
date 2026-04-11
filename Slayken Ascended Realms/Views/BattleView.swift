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

    @Environment(\.dismiss) var dismiss

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
            // Background
            Image(gameState.selectedMap.mapImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                // Enemy section
                VStack {
                    hpBar(value: enemyHP)
                        .padding(.horizontal, 30)

                    Image(enemy.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .scaleEffect(enemyHit ? 0.9 : 1)
                        .opacity(enemyHit ? 0.6 : 1)
                        .animation(.easeInOut(duration: 0.2), value: enemyHit)
                }

                Spacer()

                // Player section
                VStack(spacing: 18) {
                    Image(player.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .scaleEffect(playerHit ? 0.9 : 1)
                        .opacity(playerHit ? 0.6 : 1)
                        .animation(.easeInOut(duration: 0.2), value: playerHit)

                    hpBar(value: playerHP)
                        .padding(.horizontal, 30)

                    // Action bar
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
                            if isAuto { startAutoAttack() }
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
                }
            }

            // Overlays
            if showVictory {
                VictoryView {
                    dismiss()
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
        .onTapGesture { attack() }
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

    // MARK: - UI Helpers
    func hpBar(value: CGFloat) -> some View {
        GeometryReader { geo in
            let safe = max(0, min(1, value))

            ZStack(alignment: .leading) {

                // BACKGROUND
                Capsule()
                    .fill(Color.black.opacity(0.5))

                // FILL (jetzt korrekt von links!)
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

                // BORDER
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)

                // TEXT (zentriert lassen wir extra!)
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
        .frame(height: 10)
        .padding(.horizontal, 50)
    }

    // MARK: - Actions
    func attack() {
        guard !showVictory && !showDefeat else { return }

        playerHit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            playerHit = false
        }

        // Player attack
        let playerDamage = player.attack / enemy.hp
        withAnimation(.easeOut(duration: 0.2)) {
            enemyHP -= playerDamage
        }

        if enemyHP <= 0 {
            enemyHP = 0
            showVictory = true
            return
        }

        // Enemy counter attack
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
        hp: 100,
        attack: 20
    )
    let sampleEnemy = CharacterStats(
        name: "Goblin",
        image: "sar_dragon",
        hp: 80,
        attack: 12
    )
    return BattleView(player: samplePlayer, enemy: sampleEnemy)
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
