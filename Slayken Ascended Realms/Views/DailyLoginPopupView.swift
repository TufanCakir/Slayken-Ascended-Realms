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

    private var panelFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.92),
                activeTheme?.primary.color.opacity(0.8)
                    ?? Color(red: 0.24, green: 0.16, blue: 0.12),
                activeTheme?.secondary.color.opacity(0.5)
                    ?? Color(red: 0.4, green: 0.24, blue: 0.18),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            .padding(24)
            .frame(maxWidth: 360)
            .background(
                panelFill,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 24, y: 16)
            .padding(.horizontal, 24)
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
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}
