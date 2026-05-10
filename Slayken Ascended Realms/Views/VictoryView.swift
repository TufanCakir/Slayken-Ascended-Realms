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
    let characterRewards: [GlobeBattle.CharacterReward]
    let skinRewards: [StorePackSkinReward]
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
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    victoryHeader
                    levelSummaryRow
                    ascendedXPPanel
                    rewardPanel
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }

            continueButton
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
                .background(Color.black.opacity(0.24))
        }
        .onAppear {
            animate = true
        }
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

    private var victoryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "crown.fill")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.black.opacity(0.82))
            }
            .frame(width: 46, height: 46)
            .scaleEffect(animate ? 1 : 0.88)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7),
                value: animate
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("VICTORY")
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(defeatedEnemies) Gegner besiegt")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            Color.black.opacity(0.42),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var levelSummaryRow: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Char XP",
                value: "+\(xpReward)",
                detail: levelAfter > levelBefore
                    ? "Lv. \(levelBefore) -> \(levelAfter)"
                    : "Lv. \(levelAfter)",
                accent: .green
            )

            summaryCard(
                title: "Ascended XP",
                value: "+\(ascendedXPReward)",
                detail: ascendedLevelAfter > ascendedLevelBefore
                    ? "Asc. \(ascendedLevelBefore) -> \(ascendedLevelAfter)"
                    : "Asc. \(ascendedLevelAfter)",
                accent: .yellow
            )
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("Continue")
                .font(.system(size: 15, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    Color.white.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }

    private let rewardColumns = [
        GridItem(.adaptive(minimum: 64, maximum: 78), spacing: 8)
    ]

    private var rewardPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !rewards.isEmpty {
                sectionTitle("Belohnungen")
                rewardRow
            }

            if !characterRewards.isEmpty {
                Divider().overlay(.white.opacity(0.16))
                sectionTitle("Charaktere")
                characterRewardRow
            }

            if !skinRewards.isEmpty {
                Divider().overlay(.white.opacity(0.16))
                sectionTitle("Skins")
                skinRewardRow
            }

            if !cardRewards.isEmpty {
                Divider().overlay(.white.opacity(0.16))
                sectionTitle("Karten")
                cardRewardRow
            }
        }
        .padding(12)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var rewardRow: some View {
        LazyVGrid(columns: rewardColumns, spacing: 8) {
            ForEach(rewards) { reward in
                if let currency = currencies.first(where: {
                    $0.code == reward.currency
                }) {
                    rewardItem(currency: currency, amount: reward.amount)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var cardRewardRow: some View {
        LazyVGrid(columns: rewardColumns, spacing: 8) {
            ForEach(cardRewards) { reward in
                rewardItem(
                    title: cardName(for: reward.cardID),
                    subtitle: "+\(reward.amount)",
                    imageName: cardImage(for: reward.cardID),
                    systemName: "rectangle.stack.fill"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var characterRewardRow: some View {
        LazyVGrid(columns: rewardColumns, spacing: 8) {
            ForEach(characterRewards) { reward in
                rewardItem(
                    title: characterName(for: reward.characterID),
                    subtitle: "Neu",
                    imageName: characterImage(for: reward.characterID),
                    systemName: "person.fill"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var skinRewardRow: some View {
        LazyVGrid(columns: rewardColumns, spacing: 8) {
            ForEach(skinRewards) { reward in
                rewardItem(
                    title: skinName(
                        characterID: reward.characterID,
                        skinID: reward.skinID
                    ),
                    subtitle: "Skin",
                    imageName: skinImage(
                        characterID: reward.characterID,
                        skinID: reward.skinID
                    ),
                    systemName: "sparkles"
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var ascendedXPPanel: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.yellow)

                Text("Ascended XP +\(ascendedXPReward)")
                    .font(.system(size: 13, weight: .black))

                Spacer()

                Text(
                    ascendedLevelAfter > ascendedLevelBefore
                        ? "Asc. Lv.\(ascendedLevelBefore) -> Lv.\(ascendedLevelAfter)"
                        : "Asc. Lv.\(ascendedLevelAfter)"
                )
                .font(.system(size: 11, weight: .black))
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
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
    }

    private func summaryCard(
        title: String,
        value: String,
        detail: String,
        accent: Color
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.66))

            Text(value)
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(.horizontal, 8)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
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
        VStack(spacing: 4) {
            if let imageName {
                RemoteAssetImage(imageName, contentMode: .fit) {
                    Image(systemName: systemName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.yellow)
                }
                .frame(width: 24, height: 24)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.yellow)
            }

            Text(subtitle)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)

            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 66, height: 62)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func cardName(for cardID: String) -> String {
        gameState.abilityCards.first(where: { $0.id == cardID })?.name ?? cardID
    }

    private func characterName(for characterID: String) -> String {
        gameState.summonCharacters.first(where: { $0.id == characterID })?.name
            ?? characterID
    }

    private func characterImage(for characterID: String) -> String? {
        gameState.summonCharacters.first(where: { $0.id == characterID })?
            .summonImage
    }

    private func skinName(characterID: String, skinID: String) -> String {
        gameState.summonCharacters.first(where: { $0.id == characterID })?
            .skins.first(where: { $0.id == skinID })?.name ?? skinID
    }

    private func skinImage(characterID: String, skinID: String) -> String? {
        gameState.summonCharacters.first(where: { $0.id == characterID })?
            .skins.first(where: { $0.id == skinID })?.summonImage
            ?? characterImage(for: characterID)
    }

    private func cardImage(for cardID: String) -> String? {
        gameState.abilityCards.first(where: { $0.id == cardID })?.image
    }
}
