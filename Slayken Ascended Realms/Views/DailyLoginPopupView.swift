//
//  DailyLoginPopupView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct DailyLoginPopupView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let rewardState: DailyLoginRewardState
    let onClaim: () -> Void

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
    }

    private var accentColor: Color {
        activeTheme?.accent.color.opacity(0.9)
            ?? Color(red: 0.86, green: 0.3, blue: 0.18)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("DAILY LOGIN")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.72))

                VStack(spacing: 8) {
                    Text("Tag \(rewardState.dayNumber)")
                        .font(
                            .system(size: 16, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(accentColor)

                    Image(systemName: rewardState.reward.icon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(accentColor)

                    Text(rewardState.reward.title)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text(rewardState.reward.subtitle)
                        .font(
                            .system(size: 15, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(.white.opacity(0.76))

                    Text(rewardState.reward.message)
                        .font(
                            .system(size: 14, weight: .medium, design: .rounded)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.88))
                }

                VStack(spacing: 10) {
                    ForEach(rewardState.reward.rewards) { reward in
                        rewardRow(reward)
                    }
                }

                Button(action: onClaim) {
                    Text(rewardState.reward.buttonTitle)
                        .font(
                            .system(size: 15, weight: .black, design: .rounded)
                        )
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            accentColor,
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background {
                ZStack {
                    if let background = activeTheme?.background {
                        RemoteAssetImage(background) {
                            panelFallback
                        }
                    } else {
                        panelFallback
                    }

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.42),
                            Color.black.opacity(0.72),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(panelShape)
            }
            .overlay {
                panelShape
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .padding()
        }
    }

    private func rewardRow(_ reward: CurrencyAmount) -> some View {
        let currency = gameState.currencies.first { $0.code == reward.currency }

        return HStack(spacing: 12) {
            Image(systemName: currency?.icon ?? "gift.fill")
                .frame(width: 22, height: 22)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(currency?.name ?? reward.currency.capitalized)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("+\(reward.amount)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var panelFallback: some View {
        LinearGradient(
            colors: [
                activeTheme?.primary.color.opacity(0.82)
                    ?? Color(red: 0.14, green: 0.18, blue: 0.32),
                activeTheme?.secondary.color.opacity(0.76)
                    ?? Color(red: 0.08, green: 0.10, blue: 0.22),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    let gameState = GameState()
    gameState.currencies = [
        CurrencyDefinition(
            code: "gold",
            name: "Gold",
            icon: "crown.fill",
            assetIcon: nil,
            sortOrder: 0
        ),
        CurrencyDefinition(
            code: "gems",
            name: "Gems",
            icon: "sparkles",
            assetIcon: nil,
            sortOrder: 1
        ),
    ]

    return DailyLoginPopupView(
        rewardState: DailyLoginRewardState(
            reward: DailyLoginRewardDefinition(
                id: "preview-day-7",
                day: 7,
                title: "Realm Bonus",
                subtitle: "Dein Wochenbonus ist bereit.",
                message:
                    "Logge dich morgen wieder ein, um die naechste Belohnung freizuschalten.",
                buttonTitle: "Belohnung abholen",
                icon: "gift.fill",
                rewards: [
                    CurrencyAmount(currency: "gold", amount: 2500),
                    CurrencyAmount(currency: "gems", amount: 120),
                ]
            ),
            dayNumber: 7
        ),
        onClaim: {}
    )
    .environmentObject(gameState)
    .environmentObject(ThemeManager())
}
