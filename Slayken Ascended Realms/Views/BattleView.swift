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

    var body: some View {
        ZStack {
            // 🌄 BACKGROUND
            Image(gameState.selectedBackground.image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                // ENEMY
                VStack {
                    Image(enemy.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)

                    hpBar(value: enemyHP)
                }

                Spacer()

                Text("Tap to Attack")
                    .foregroundStyle(
                        theme.selectedTheme?.primary.color ?? .white
                    )
                    .shadow(
                        color: (theme.selectedTheme?.glow.color ?? .blue)
                            .opacity(0.6),
                        radius: 8
                    )

                Spacer()

                // PLAYER
                VStack {
                    hpBar(value: playerHP)

                    Image(player.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                }
            }
            .padding()

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
        .onTapGesture {
            attack()
        }
        .onAppear {
            playerHP = 1
            enemyHP = 1
        }
    }

    // MARK: - UI Helpers
    func hpBar(value: CGFloat) -> some View {
        GeometryReader { geo in
            let safe = max(0, min(1, value))

            ZStack(alignment: .leading) {

                Capsule()
                    .fill(
                        (theme.selectedTheme?.accent.color ?? .black)
                            .opacity(0.2)
                    )

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
                    .shadow(
                        color: (theme.selectedTheme?.glow.color ?? .red)
                            .opacity(0.7),
                        radius: 8
                    )
                    .animation(.linear(duration: 0.2), value: safe)
            }
        }
        .frame(height: 10)
        .padding(.horizontal, 50)
    }

    // MARK: - Actions
    func attack() {
        guard !showVictory && !showDefeat else { return }

        // 🔥 PLAYER greift an
        let playerDamage = player.attack / enemy.hp

        withAnimation {
            enemyHP -= playerDamage
        }

        if enemyHP <= 0 {
            enemyHP = 0
            showVictory = true
            return
        }

        // 🔥 ENEMY greift zurück
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let enemyDamage = enemy.attack / player.hp

            withAnimation {
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
        image: "dragon",
        hp: 80,
        attack: 12
    )
    return BattleView(player: samplePlayer, enemy: sampleEnemy)
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
