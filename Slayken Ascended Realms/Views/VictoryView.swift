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

    let currencies: [CurrencyDefinition]
    let rewards: [CurrencyAmount]

    var onContinue: () -> Void

    var body: some View {
        ZStack {

            // 🌄 BACKGROUND
            Image(gameState.selectedBackground.image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: 6)

            // 🌑 DARK OVERLAY
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // ✨ GLOW
            Circle()
                .fill((theme.selectedTheme?.glow.color ?? .blue).opacity(0.4))
                .blur(radius: 140)
                .scaleEffect(animate ? 1.3 : 0.8)
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: animate
                )

            VStack {

                Spacer()

                // 🏆 CENTER CARD
                VStack(spacing: 24) {

                    // TITLE
                    Text("VICTORY")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.selectedTheme?.secondary.color
                                        ?? .white,
                                    theme.selectedTheme?.primary.color ?? .blue,
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
                        .scaleEffect(animate ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 1).repeatForever(),
                            value: animate
                        )

                    // OPTIONAL SUBTEXT
                    Text("Enemies Defeated")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    // ✨ REWARD PLACEHOLDER
                    HStack(spacing: 16) {
                        ForEach(rewards) { reward in
                            if let currency = currencies.first(where: {
                                $0.code == reward.currency
                            }) {
                                rewardItem(
                                    currency: currency,
                                    amount: reward.amount
                                )
                            }
                        }
                    }

                    // 🔘 BUTTON
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        theme.selectedTheme?.primary.color
                                            ?? .blue,
                                        theme.selectedTheme?.secondary.color
                                            ?? .purple,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                            .shadow(
                                color: (theme.selectedTheme?.glow.color ?? .blue)
                                    .opacity(0.6),
                                radius: 10
                            )
                    }
                    .padding(.top, 10)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.7))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .onAppear {
            animate = true
        }
    }

    // MARK: - Reward Item
    private func rewardItem(currency: CurrencyDefinition, amount: Int)
        -> some View
    {
        VStack(spacing: 6) {

            // 🔥 PRIORITÄT: Asset Icon
            if let asset = currency.assetIcon, UIImage(named: asset) != nil {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: currency.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.yellow)
            }

            Text("\(amount)")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)

            Text(currency.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(width: 90, height: 80)
        .background(
            Color.black.opacity(0.4),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }
}

#Preview {
    VictoryView(
        currencies: loadCurrencyDefinitions(),
        rewards: [
            CurrencyAmount(currency: "coins", amount: 120),
            CurrencyAmount(currency: "crystals", amount: 5),
        ],
        onContinue: {}
    )
    .environmentObject(GameState())
    .environmentObject(ThemeManager())
}
