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

    let campaignTitle: String
    let campaignSubtitle: String
    let rewards: [DailyLoginRewardDefinition]
    let rewardState: DailyLoginRewardState
    let onClaim: () -> Void

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var accentColor: Color {
        activeTheme?.accent.color.opacity(0.9)
            ?? Color(red: 0.18, green: 0.72, blue: 0.92)
    }

    private var highlightedDay: Int {
        rewardState.dayNumber
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                headerBlock
                featuredRewardCard
                rewardCalendarList

                Button(action: onClaim) {
                    Text(rewardState.reward.buttonTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [
                                    accentColor,
                                    accentColor.opacity(0.72),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.17, blue: 0.28).opacity(0.98),
                        Color(red: 0.03, green: 0.09, blue: 0.18).opacity(0.98),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .padding(16)
        }
    }

    private var headerBlock: some View {
        VStack(spacing: 6) {
            Text(campaignTitle)
                .font(.system(size: 30, weight: .light, design: .rounded))
                .foregroundStyle(.white)

            Text(campaignSubtitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var featuredRewardCard: some View {
        VStack(spacing: 10) {
            Text("Tag \(rewardState.dayNumber)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.72))

            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 112, height: 112)

                Image(systemName: rewardState.reward.icon)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(rewardState.reward.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Text(rewardState.reward.message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(rewardState.reward.rewards) { reward in
                    currencyRewardRow(reward)
                }
                ForEach(rewardState.reward.characterRewards) { reward in
                    characterRewardRow(reward)
                }
                ForEach(rewardState.reward.cardRewards) { reward in
                    cardRewardRow(reward)
                }
            }
        }
        .padding(16)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }

    private var rewardCalendarList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alle Login-Boni")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(rewards) { reward in
                        rewardCalendarRow(reward)
                    }
                }
                .padding(.trailing, 4)
            }
            .frame(maxHeight: 250)
        }
    }

    private func rewardCalendarRow(_ reward: DailyLoginRewardDefinition) -> some View {
        let isActive = reward.day == highlightedDay

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isActive
                            ? accentColor.opacity(0.26)
                            : Color.white.opacity(0.06)
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: reward.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Tag \(reward.day) · \(reward.title)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(rewardSummary(for: reward))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(1)
            }

            Spacer()

            if isActive {
                Text("Heute")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.9), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isActive ? Color.white.opacity(0.10) : Color.black.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isActive ? accentColor.opacity(0.7) : .white.opacity(0.06),
                    lineWidth: 1
                )
        }
    }

    private func rewardSummary(for reward: DailyLoginRewardDefinition) -> String {
        let currencyParts = reward.rewards.map { "+\($0.amount) \($0.currency)" }
        let characterParts = reward.characterRewards.map { _ in "+ Charakter" }
        let cardParts = reward.cardRewards.map { "+ Karte x\($0.amount)" }

        return (currencyParts + characterParts + cardParts)
            .joined(separator: " · ")
    }

    private func currencyRewardRow(_ reward: CurrencyAmount) -> some View {
        let currency = gameState.currencies.first { $0.code == reward.currency }

        return HStack(spacing: 12) {
            currencyIconView(
                assetIconName: currency?.assetIcon,
                symbolName: currency?.icon
            )
            .frame(width: 22, height: 22)

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
            Color.black.opacity(0.24),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func characterRewardRow(_ reward: GiftCharacterReward) -> some View {
        let character = gameState.summonCharacters.first {
            $0.id == reward.characterID
        }

        return HStack(spacing: 12) {
            rewardPreviewImage(
                character?.summonImage,
                fallbackSystemName: "person.fill"
            )
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(character?.name ?? reward.characterID)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Neuer Charakter")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.24),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func cardRewardRow(_ reward: GiftCardReward) -> some View {
        let card = gameState.abilityCards.first { $0.id == reward.cardID }

        return HStack(spacing: 12) {
            rewardPreviewImage(
                card?.image,
                fallbackSystemName: "rectangle.stack.fill"
            )
            .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(card?.name ?? reward.cardID)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Skill-Karte x\(reward.amount)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.24),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    @ViewBuilder
    private func rewardPreviewImage(
        _ imageName: String?,
        fallbackSystemName: String
    ) -> some View {
        if let imageName,
            RemoteContentManager.hasCachedOrBundledImage(named: imageName)
        {
            RemoteAssetImage(imageName, contentMode: .fill) {
                Color.clear
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            Image(systemName: fallbackSystemName)
                .foregroundStyle(.white)
        }
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
    gameState.summonCharacters = [
        SummonCharacter(
            id: "zaron",
            name: "Zaron",
            summonImage: "preview_zaron",
            model: "zaron",
            battleModel: nil,
            texture: nil,
            element: nil,
            rarity: 5,
            hp: 1200,
            attack: 240,
            skins: []
        )
    ]
    gameState.abilityCards = [
        AbilityCardDefinition(
            id: "slash_red",
            name: "Slash Red",
            image: "skill_slash_red",
            element: "fire",
            rarity: 3,
            damageMultiplier: 1.3,
            particleEffect: "slash",
            description: "Preview card",
            manaCost: 15,
            maxLevel: 30,
            maxStars: 5,
            duplicatesPerLevel: 2,
            levelsPerStar: 6,
            damageGrowth: 1.08,
            targeting: .single
        )
    ]

    let previewRewards = [
        DailyLoginRewardDefinition(
            id: "preview-day-6",
            day: 6,
            title: "Crystal Surge",
            subtitle: "Mehr Vorrat",
            message: "Vorschau-Belohnung fuer die Kampagnenliste.",
            buttonTitle: "Tag 6 abholen",
            icon: "sparkles",
            rewards: [
                CurrencyAmount(currency: "gems", amount: 120)
            ],
            characterRewards: [],
            cardRewards: []
        ),
        DailyLoginRewardDefinition(
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
            ],
            characterRewards: [GiftCharacterReward(characterID: "zaron")],
            cardRewards: [GiftCardReward(cardID: "slash_red", amount: 1)]
        ),
        DailyLoginRewardDefinition(
            id: "preview-day-8",
            day: 8,
            title: "Hero Drop",
            subtitle: "Seltener Bonus",
            message: "Noch ein Beispiel fuer die Popup-Liste.",
            buttonTitle: "Tag 8 abholen",
            icon: "star.fill",
            rewards: [
                CurrencyAmount(currency: "gold", amount: 3200)
            ],
            characterRewards: [],
            cardRewards: [GiftCardReward(cardID: "slash_red", amount: 2)]
        ),
    ]

    return DailyLoginPopupView(
        campaignTitle: "Login Bonus",
        campaignSubtitle: "Alle Belohnungen dieser Kampagne im Ueberblick",
        rewards: previewRewards,
        rewardState: DailyLoginRewardState(
            reward: previewRewards[1],
            dayNumber: 7
        ),
        onClaim: {}
    )
    .environmentObject(gameState)
    .environmentObject(ThemeManager())
}
