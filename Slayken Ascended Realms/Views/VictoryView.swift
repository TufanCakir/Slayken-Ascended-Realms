//
//  VictoryView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct VictoryView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState

    @State private var animate = false

    let currencies: [CurrencyDefinition]
    let rewards: [CurrencyAmount]
    let cardRewards: [GlobeBattle.CardReward]
    let xpReward: Int
    let ascendedXPReward: Int
    let levelBefore: Int
    let levelAfter: Int
    let ascendedLevelBefore: Int
    let ascendedLevelAfter: Int
    let defeatedEnemies: Int

    var onContinue: () -> Void

    var body: some View {

        VStack {

            rewardRow
            if !cardRewards.isEmpty {
                cardRewardRow
            }
            Spacer()
            ascendedXPPanel
            Spacer()

            Text("VICTORY")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            theme.selectedTheme?.secondary.color ?? .white,
                            theme.selectedTheme?.primary.color ?? .blue,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: (theme.selectedTheme?.glow.color ?? .blue).opacity(
                        0.9
                    ),
                    radius: 18
                )

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color ?? .blue,
                                theme.selectedTheme?.secondary.color ?? .purple,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)
        }
        .padding()
        .padding(.horizontal, 24)
        .onAppear {
            animate = true
        }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    Image(theme.background)
                        .resizable()
                        .scaledToFill()
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.6),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    private var rewardRow: some View {
        HStack(spacing: 10) {
            ForEach(rewards) { reward in
                if let currency = currencies.first(where: {
                    $0.code == reward.currency
                }) {
                    rewardItem(currency: currency, amount: reward.amount)
                }
            }
        }
    }

    private var cardRewardRow: some View {
        HStack(spacing: 10) {
            ForEach(cardRewards) { reward in
                rewardItem(
                    title: cardName(for: reward.cardID),
                    subtitle: "+\(reward.amount)",
                    imageName: cardImage(for: reward.cardID),
                    systemName: "rectangle.stack.fill"
                )
            }
        }
    }

    private var ascendedXPPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.yellow)

                Text("Ascended XP +\(ascendedXPReward)")
                    .font(.system(size: 15, weight: .black))

                Spacer()

                Text(
                    ascendedLevelAfter > ascendedLevelBefore
                        ? "Asc. Lv.\(ascendedLevelBefore) -> Lv.\(ascendedLevelAfter)"
                        : "Asc. Lv.\(ascendedLevelAfter)"
                )
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(
                    ascendedLevelAfter > ascendedLevelBefore
                        ? .green : .white.opacity(0.82)
                )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.72)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            Color.black.opacity(0.45),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .foregroundStyle(.white)
    }

    private func rewardItem(currency: CurrencyDefinition, amount: Int)
        -> some View
    {
        rewardItem(
            title: currency.name,
            subtitle: "+\(amount)",
            imageName: currency.assetIcon,
            systemName: currency.icon
        )
    }

    private func rewardItem(
        title: String,
        subtitle: String,
        imageName: String?,
        systemName: String
    ) -> some View {
        VStack(spacing: 6) {
            if let imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.yellow)
            }

            Text(subtitle)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
        }
        .frame(width: 84, height: 76)
        .background(
            Color.black.opacity(0.45),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func cardName(for cardID: String) -> String {
        gameState.abilityCards.first(where: { $0.id == cardID })?.name ?? cardID
    }

    private func cardImage(for cardID: String) -> String? {
        gameState.abilityCards.first(where: { $0.id == cardID })?.image
    }
}

#Preview {
    VictoryView(
        currencies: loadCurrencyDefinitions(),
        rewards: [
            CurrencyAmount(currency: "coins", amount: 120),
            CurrencyAmount(currency: "crystals", amount: 5),
        ],
        cardRewards: [
            GlobeBattle.CardReward(cardID: "slash_red", amount: 1)
        ],
        xpReward: 140,
        ascendedXPReward: 140,
        levelBefore: 1,
        levelAfter: 2,
        ascendedLevelBefore: 1,
        ascendedLevelAfter: 2,
        defeatedEnemies: 3,
        onContinue: {}
    )
    .environmentObject(GameState())
    .environmentObject(ThemeManager())
}
