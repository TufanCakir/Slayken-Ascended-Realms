//
//  GiftView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GiftView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let gifts: [GiftBoxDefinition]
    let onClaim: (GiftBoxDefinition) -> Void
    let onClose: () -> Void

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    activeTheme?.primary.color.opacity(0.72)
                        ?? Color(red: 0.16, green: 0.12, blue: 0.12),
                    activeTheme?.secondary.color.opacity(0.45)
                        ?? Color(red: 0.28, green: 0.16, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(gifts) { gift in
                            giftCard(gift)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .padding(.top, 20)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Giftbox")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("Manuelle Geschenkboxen fuer den Spieler")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private func giftCard(_ gift: GiftBoxDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(gift.title)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    Text(gift.subtitle)
                        .font(
                            .system(size: 13, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                Image(systemName: gift.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            Text(gift.message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))

            VStack(spacing: 8) {
                ForEach(gift.rewards) { reward in
                    rewardRow(reward)
                }
            }

            Button {
                onClaim(gift)
            } label: {
                Text(gift.buttonTitle)
                    .font(.system(size: 15, weight: .black, design: .rounded))
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
        .padding(18)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func rewardRow(_ reward: CurrencyAmount) -> some View {
        let currency = gameState.currencies.first { $0.code == reward.currency }

        return HStack {
            Image(systemName: currency?.icon ?? "gift.fill")
                .foregroundStyle(accentColor)
                .frame(width: 20)

            Text(currency?.name ?? reward.currency.capitalized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("+\(reward.amount)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private var accentColor: Color {
        activeTheme?.accent.color.opacity(0.9)
            ?? Color(red: 0.86, green: 0.3, blue: 0.18)
    }
}
