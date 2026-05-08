//
//  DailyLoginView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct DailyLoginView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager
    @State private var didScrollToHighlightedDay = false
    @State private var revealCards = false

    let campaigns: [LoginRewardCampaign]
    let selectedCampaignID: String?
    let campaignTitle: String
    let campaignSubtitle: String
    let rewards: [DailyLoginRewardDefinition]
    let currencies: [CurrencyDefinition]
    let availableReward: DailyLoginRewardState?
    let onClaim: () -> Void
    let onSelectCampaign: (String) -> Void
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

    private var activeRewardBackground: String? {
        availableReward?.reward.background
            ?? rewards.first {
                ($0.background ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty == false
            }?.background
    }

    var body: some View {

        VStack(spacing: 20) {
            header
            campaignSelector
            statusCard

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 14) {
                        ForEach(rewards) { reward in
                            rewardDayCard(reward)
                                .opacity(cardOpacity(for: reward))
                                .offset(y: cardOffset(for: reward))
                                .animation(
                                    .spring(
                                        response: 0.55,
                                        dampingFraction: 0.84
                                    )
                                    .delay(cardAnimationDelay(for: reward)),
                                    value: revealCards
                                )
                                .id(reward.day)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .onAppear {
                    guard !didScrollToHighlightedDay else { return }
                    didScrollToHighlightedDay = true
                    revealCards = false
                    DispatchQueue.main.async {
                        revealCards = true
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo(highlightedDay, anchor: .top)
                        }
                    }
                }
                .onChange(of: selectedCampaignID) { _, _ in
                    didScrollToHighlightedDay = false
                    revealCards = false
                    DispatchQueue.main.async {
                        revealCards = true
                        withAnimation(.easeInOut(duration: 0.35)) {
                            proxy.scrollTo(highlightedDay, anchor: .top)
                        }
                        didScrollToHighlightedDay = true
                    }
                }
            }
        }
        .padding(.top, 20)
        .background {
            ZStack {
                if let activeRewardBackground,
                    !activeRewardBackground.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                {
                    RemoteAssetImage(activeRewardBackground, contentMode: .fill)
                    {
                        backgroundFallback
                    }
                } else if let theme = theme.selectedTheme {
                    RemoteAssetImage(theme.background, contentMode: .fill) {
                        backgroundFallback
                    }
                } else {
                    backgroundFallback
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
                Text(campaignTitle)
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text(campaignSubtitle)
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

    private var campaignSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(campaigns) { campaign in
                    Button {
                        onSelectCampaign(campaign.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(campaign.title)
                                .font(
                                    .system(
                                        size: 13,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                            Text(campaign.subtitle)
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .medium,
                                        design: .rounded
                                    )
                                )
                                .lineLimit(1)
                                .opacity(0.78)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedCampaignID == campaign.id
                                ? Color.white.opacity(0.18)
                                : Color.black.opacity(0.28),
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .stroke(
                                selectedCampaignID == campaign.id
                                    ? .white.opacity(0.18)
                                    : .white.opacity(0.08),
                                lineWidth: 1
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var statusCard: some View {
        VStack(spacing: 14) {
            Text(
                availableReward == nil
                    ? "Heute bereits eingesammelt" : "Belohnung verfügbar"
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
                Text("Komm morgen wieder für den nächsten Kalendertag.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
        .padding()
        .background {
            loginBackgroundImage(
                named: availableReward?.reward.background,
                fallback: Color.black.opacity(0.34)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
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

                rewardIconView(
                    assetIconName: reward.assetIcon,
                    symbolName: reward.icon,
                    tintColor: isHighlighted
                        ? Color.white : .white.opacity(0.72)
                )
                .frame(width: 22, height: 22)
            }

            Text(reward.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(reward.subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))

            VStack(spacing: 8) {
                ForEach(reward.rewards) { item in
                    currencyRewardRow(item)
                }

                ForEach(reward.characterRewards) { item in
                    characterRewardRow(item)
                }

                ForEach(reward.cardRewards) { item in
                    cardRewardRow(item)
                }
            }
        }
        .padding()
        .background {
            loginBackgroundImage(
                named: reward.background,
                fallback: Color.black.opacity(0.34)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(
            color: isHighlighted ? .orange.opacity(0.16) : .clear,
            radius: 18
        )
    }

    private func cardAnimationDelay(for reward: DailyLoginRewardDefinition)
        -> Double
    {
        let distanceFromHighlight = abs(reward.day - highlightedDay)
        return min(Double(distanceFromHighlight) * 0.035, 0.42)
    }

    private func cardOpacity(for reward: DailyLoginRewardDefinition) -> Double {
        revealCards || reward.day == highlightedDay ? 1 : 0
    }

    private func cardOffset(for reward: DailyLoginRewardDefinition) -> CGFloat {
        revealCards || reward.day == highlightedDay ? 0 : 22
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

    private func currencyRewardRow(_ reward: CurrencyAmount) -> some View {
        let currency = currencies.first { $0.code == reward.currency }

        return HStack {
            currencyIconView(
                assetIconName: currency?.assetIcon,
                symbolName: currency?.icon
            )
            .frame(width: 20, height: 20)

            Text(currency?.name ?? reward.currency.capitalized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("+\(reward.amount)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
        }
    }

    private func characterRewardRow(_ reward: GiftCharacterReward) -> some View
    {
        let character = gameState.summonCharacters.first {
            $0.id == reward.characterID
        }

        return HStack(spacing: 10) {
            rewardPreviewImage(
                character?.summonImage,
                fallbackSystemName: "person.fill"
            )
            .frame(width: 24, height: 24)

            Text(character?.name ?? reward.characterID)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("Charakter")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.orange.opacity(0.9))
        }
    }

    private func cardRewardRow(_ reward: GiftCardReward) -> some View {
        let card = gameState.abilityCards.first { $0.id == reward.cardID }

        return HStack(spacing: 10) {
            rewardPreviewImage(
                card?.image,
                fallbackSystemName: "rectangle.stack.fill"
            )
            .frame(width: 24, height: 24)

            Text(card?.name ?? reward.cardID)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("x\(reward.amount)")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.cyan.opacity(0.9))
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
                Color.white.opacity(0.08)
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
            .overlay(Color.black.opacity(0.34))
        } else {
            fallback
        }
    }
}

#Preview {
    DailyLoginView(
        campaigns: [
            LoginRewardCampaign(
                id: "daily_login",
                title: "Daily Login",
                subtitle: "30 Tage Login-Belohnungen",
                resource: "daily_login",
                endsAt: nil,
                rewards: []
            )
        ],
        selectedCampaignID: "daily_login",
        campaignTitle: "Daily Login",
        campaignSubtitle: "30 Tage Login-Belohnungen",
        rewards: [
            DailyLoginRewardDefinition(
                id: "preview-day-1",
                day: 1,
                title: "Willkommensbonus",
                subtitle: "Ein starker Start für dein Abenteuer",
                message: "Du hast deine erste Tagesbelohnung erhalten.",
                buttonTitle: "Abholen",
                icon: "star.fill",
                assetIcon: nil,
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
                subtitle: "Ein starker Start für dein Abenteuer",
                message: "Du hast deine erste Tagesbelohnung erhalten.",
                buttonTitle: "Abholen",
                icon: "star.fill",
                assetIcon: nil,
                rewards: [
                    CurrencyAmount(currency: "gold", amount: 500),
                    CurrencyAmount(currency: "gems", amount: 25),
                ],
                characterRewards: [GiftCharacterReward(characterID: "zaron")],
                cardRewards: [GiftCardReward(cardID: "slash_red", amount: 1)]
            ),
            dayNumber: 1
        ),
        onClaim: {},
        onSelectCampaign: { _ in },
        onClose: {}
    )
    .environmentObject(GameState())
    .environmentObject(ThemeManager())
}
