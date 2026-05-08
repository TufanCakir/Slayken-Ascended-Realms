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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Spacer(minLength: 12)

                victoryHeader
                levelSummaryRow
                rewardSection
                if !characterRewards.isEmpty {
                    characterRewardSection
                }
                if !cardRewards.isEmpty {
                    cardRewardSection
                }
                ascendedXPPanel
                continueButton
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
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
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.yellow)
                .scaleEffect(animate ? 1 : 0.88)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7),
                    value: animate
                )

            Text("VICTORY")
                .font(.system(size: 46, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text("Du hast \(defeatedEnemies) Gegner besiegt.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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

    private var rewardSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Belohnungen")
            rewardRow
        }
    }

    private var cardRewardSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Karten")
            cardRewardRow
        }
    }

    private var characterRewardSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Charaktere")
            characterRewardRow
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("Continue")
                .font(.system(size: 16, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Color.white.opacity(0.92),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
    }

    private let rewardColumns = [
        GridItem(.adaptive(minimum: 72, maximum: 90), spacing: 10)
    ]

    private var rewardRow: some View {
        LazyVGrid(columns: rewardColumns, spacing: 10) {
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
        LazyVGrid(columns: rewardColumns, spacing: 10) {
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
        LazyVGrid(columns: rewardColumns, spacing: 10) {
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
        .padding()
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
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
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.66))

            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(.horizontal, 10)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        VStack(spacing: 6) {
            if let imageName {
                RemoteAssetImage(imageName, contentMode: .fit) {
                    Image(systemName: systemName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.yellow)
                }
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
                .minimumScaleFactor(0.7)
        }
        .frame(width: 76, height: 72)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
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

    private func cardImage(for cardID: String) -> String? {
        gameState.abilityCards.first(where: { $0.id == cardID })?.image
    }
}
