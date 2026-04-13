//
//  VictoryView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct VictoryView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState

    @State private var animate = false

    var onContinue: () -> Void

    var body: some View {
        ZStack {
            // 🌄 BACKGROUND
            Image(gameState.selectedBackground.image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // ❄️ LIGHT GLOW
            Circle()
                .fill(Color.white.opacity(0.25))
                .blur(radius: 140)
                .scaleEffect(animate ? 1.3 : 0.7)
                .animation(
                    .easeInOut(duration: 2).repeatForever(),
                    value: animate
                )

            VStack(spacing: 40) {

                Spacer()

                // 🏆 TITLE
                Text("VICTORY")
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (theme.selectedTheme?.secondary.color ?? .white),
                                (theme.selectedTheme?.primary.color ?? .blue),
                                (theme.selectedTheme?.accent.color ?? .black),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: (theme.selectedTheme?.glow.color ?? .blue)
                            .opacity(0.9),
                        radius: 20
                    )
                    .scaleEffect(animate ? 1.08 : 0.95)
                    .animation(
                        .easeInOut(duration: 1).repeatForever(),
                        value: animate
                    )

                // 🔘 BUTTON
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    theme.selectedTheme?.primary.color ?? .blue,
                                    theme.selectedTheme?.secondary.color
                                        ?? .blue,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.6), radius: 10)
                }
                .padding(.horizontal, 40)
                .scaleEffect(animate ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(),
                    value: animate
                )
                .padding(.horizontal, 50)
                Spacer()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    VictoryView(onContinue: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
