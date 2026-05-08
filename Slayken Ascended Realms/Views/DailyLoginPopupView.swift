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
    @State private var countdownNow = Date()

    let campaignTitle: String
    let campaignSubtitle: String
    let campaignEndsAt: String?
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
                        .font(
                            .system(size: 16, weight: .black, design: .rounded)
                        )
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
        .task {
            while !Task.isCancelled {
                countdownNow = .now
                try? await Task.sleep(for: .seconds(60))
            }
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

            if let timingText = EventDateSupport.displayText(
                endsAt: campaignEndsAt,
                now: countdownNow
            ) {
                Text(timingText)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featuredRewardCard: some View {
        ZStack {
            loginBackgroundImage(
                named: rewardState.reward.background,
                fallback: Color.black.opacity(0.2)
            )
        }
        .frame(height: 260)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var rewardCalendarList: some View {
        VStack(alignment: .leading, spacing: 10) {

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(rewards) { reward in
                        rewardCalendarRow(reward)
                    }
                }
                .padding(.top)
            }
            .frame(maxHeight: 250)
        }
    }

    private func rewardCalendarRow(_ reward: DailyLoginRewardDefinition)
        -> some View
    {
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

                rewardIconView(
                    assetIconName: reward.assetIcon,
                    symbolName: reward.icon,
                    tintColor: .white
                )
                .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Tag \(reward.day) · \(reward.title)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(rewardSummary(for: reward))
                    .font(
                        .system(size: 12, weight: .semibold, design: .rounded)
                    )
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
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func rewardSummary(for reward: DailyLoginRewardDefinition) -> String
    {
        let currencyParts = reward.rewards.map {
            "+\($0.amount) \($0.currency)"
        }
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

    private func characterRewardRow(_ reward: GiftCharacterReward) -> some View
    {
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
    private func rewardIconView(
        assetIconName: String?,
        symbolName: String,
        tintColor: Color
    ) -> some View {
        if let assetIconName,
            !assetIconName.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        {
            RemoteAssetImage(assetIconName, contentMode: .fit) {
                Image(systemName: symbolName)
                    .foregroundStyle(tintColor)
            }
        } else {
            Image(systemName: symbolName)
                .foregroundStyle(tintColor)
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

    @ViewBuilder
    private func loginBackgroundImage(
        named imageName: String?,
        fallback: Color
    ) -> some View {
        if let imageName,
            !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            RemoteAssetImage(imageName, contentMode: .fill) {
                fallback
            }
            .clipped()
            .overlay(Color.black.opacity(0.12))
        } else {
            fallback
        }
    }
}
