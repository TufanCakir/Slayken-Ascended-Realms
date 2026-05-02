//
//  DailyLoginView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct DailyLoginView: View {
    @EnvironmentObject var theme: ThemeManager

    let rewards: [DailyLoginRewardDefinition]
    let currencies: [CurrencyDefinition]
    let availableReward: DailyLoginRewardState?
    let onClaim: () -> Void
    let onClose: () -> Void

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var highlightedDay: Int {
        availableReward?.dayNumber ?? 1
    }

    private var cardStroke: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.24),
                Color.cyan.opacity(0.16),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundFallback: some View {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.11, green: 0.08, blue: 0.07),
                Color(red: 0.24, green: 0.14, blue: 0.12),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {

        VStack(spacing: 20) {
            header
            statusCard

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(rewards) { reward in
                        rewardDayCard(reward)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 20)
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    RemoteAssetImage(theme.background) {
                        Color.black.opacity(0.35)
                    }
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

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Login")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text("30 Tage Login-Belohnungen")
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

    private var statusCard: some View {
        VStack(spacing: 14) {
            Text(
                availableReward == nil
                    ? "Heute bereits eingesammelt" : "Belohnung verfuegbar"
            )
            .font(.system(size: 12, weight: .black, design: .rounded))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.72))

            if let availableReward {
                Text(
                    "Tag \(availableReward.dayNumber): \(availableReward.reward.title)"
                )
                .font(.system(size: 20, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

                Button(action: onClaim) {
                    Text(availableReward.reward.buttonTitle)
                        .font(
                            .system(size: 15, weight: .black, design: .rounded)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Color(red: 0.84, green: 0.34, blue: 0.22),
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Text("Komm morgen wieder fuer den naechsten Kalendertag.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
        .padding()
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    private func rewardDayCard(_ reward: DailyLoginRewardDefinition)
        -> some View
    {
        let isHighlighted = reward.day == highlightedDay

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tag \(reward.day)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: reward.icon)
                    .foregroundStyle(
                        isHighlighted ? Color.white : .white.opacity(0.72)
                    )
            }

            Text(reward.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(reward.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            VStack(spacing: 8) {
                ForEach(reward.rewards) { item in
                    HStack {
                        currencyIconView(
                            assetIconName: currencies.first(where: {
                                $0.code == item.currency
                            })?
                            .assetIcon,
                            symbolName: currencies.first(where: {
                                $0.code == item.currency
                            })?
                            .icon
                        )
                        .frame(width: 20, height: 20)

                        Text(
                            currencies.first(where: { $0.code == item.currency }
                            )?.name ?? item.currency.capitalized
                        )
                        .font(
                            .system(size: 14, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(.white)

                        Spacer()

                        Text("+\(item.amount)")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
        .padding()
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func currencyIconView(
        assetIconName: String?,
        symbolName: String?
    ) -> some View {
        if let assetIconName,
            RemoteContentManager.hasCachedOrBundledImage(named: assetIconName)
        {
            RemoteAssetImage(assetIconName, contentMode: .fit) {
                Color.clear
            }
        } else {
            Image(systemName: symbolName ?? "gift.fill")
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    DailyLoginView(
        rewards: [
            DailyLoginRewardDefinition(
                id: "preview-day-1",
                day: 1,
                title: "Willkommensbonus",
                subtitle: "Ein starker Start fuer dein Abenteuer",
                message: "Du hast deine erste Tagesbelohnung erhalten.",
                buttonTitle: "Abholen",
                icon: "star.fill",
                rewards: [
                    CurrencyAmount(currency: "gold", amount: 500),
                    CurrencyAmount(currency: "gems", amount: 25),
                ]
            )
        ],
        currencies: [
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
        ],
        availableReward: DailyLoginRewardState(
            reward: DailyLoginRewardDefinition(
                id: "preview-day-1",
                day: 1,
                title: "Willkommensbonus",
                subtitle: "Ein starker Start fuer dein Abenteuer",
                message: "Du hast deine erste Tagesbelohnung erhalten.",
                buttonTitle: "Abholen",
                icon: "star.fill",
                rewards: [
                    CurrencyAmount(currency: "gold", amount: 500),
                    CurrencyAmount(currency: "gems", amount: 25),
                ]
            ),
            dayNumber: 1
        ),
        onClaim: {},
        onClose: {}
    )
    .environmentObject(ThemeManager())
}
