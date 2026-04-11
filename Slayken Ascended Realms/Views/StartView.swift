//
//  StartView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import SwiftUI

struct StartView: View {

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    @State private var startGame = false

    var body: some View {
        NavigationStack {
            ZStack {

                // 🌄 BACKGROUND
                Image("sar_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // 🐉 DRAGON (RESPONSIVE + HERO)
                Image("sar_dragon")
                    .resizable()
                    .scaledToFit()

                VStack(spacing: 20) {

                    Spacer()

                    Text("Slayken")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.selectedTheme?.primary.color ?? .blue,
                                    theme.selectedTheme?.secondary.color
                                        ?? .cyan,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Ascended Realms")
                        .font(.system(size: 40, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.selectedTheme?.primary.color ?? .blue,
                                    theme.selectedTheme?.secondary.color
                                        ?? .cyan,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Spacer()

                }
            }
            // 🔥 GANZER SCREEN TAPPBAR
            .contentShape(Rectangle())
            .onTapGesture {
                startGame = true
            }
            .navigationDestination(isPresented: $startGame) {
                GameView()
                    .environmentObject(gameState)
                    .environmentObject(theme)
            }
        }
    }
}
#Preview {
    StartView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
