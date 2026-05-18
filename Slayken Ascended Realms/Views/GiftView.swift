//
//  GiftView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct GiftView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager
    @Query(sort: \PlayerClaimedGift.claimedAt) private var claimedGifts:
        [PlayerClaimedGift]

    let gifts: [GiftBoxDefinition]
    let onClaim: (GiftBoxDefinition) -> Void
    let onClose: () -> Void

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var claimedGiftIDs: Set<String> {
        Set(claimedGifts.map(\.giftID))
    }

    var body: some View {

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
        let isClaimed = claimedGiftIDs.contains(gift.id)

        return VStack(alignment: .leading, spacing: 12) {
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
                    .foregroundStyle(.white)
            }

            Text(gift.message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.84))

            VStack(spacing: 8) {
                ForEach(gift.rewards) { reward in
                    rewardRow(reward)
                }
                ForEach(gift.characterRewards) { reward in
                    characterRewardRow(reward)
                }
                ForEach(gift.cardRewards) { reward in
                    cardRewardRow(reward)
                }
            }

            Button {
                onClaim(gift)
            } label: {
                Text(isClaimed ? "Bereits abgeholt" : gift.buttonTitle)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Color.white.opacity(0.14),
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(.white.opacity(isClaimed ? 0.72 : 1))
            }
            .buttonStyle(.plain)
            .disabled(isClaimed)
            .opacity(isClaimed ? 0.65 : 1)
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

    private func rewardRow(_ reward: CurrencyAmount) -> some View {
        let currency = gameState.currencies.first { $0.code == reward.currency }

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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
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

    private func characterRewardRow(_ reward: GiftCharacterReward) -> some View
    {
        let character = gameState.summonCharacters.first {
            $0.id == reward.characterID
        }

        return HStack {
            Group {
                if let summonImage = character?.summonImage {
                    RemoteAssetImage(summonImage, contentMode: .fill) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(character?.name ?? reward.characterID.capitalized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("Charakter")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func cardRewardRow(_ reward: GiftCardReward) -> some View {
        let card = gameState.abilityCards.first { $0.id == reward.cardID }

        return HStack {
            Group {
                if let image = card?.image {
                    RemoteAssetImage(image, contentMode: .fill) {
                        Image(systemName: "sparkles")
                            .resizable()
                            .scaledToFit()
                            .padding(4)
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(card?.name ?? reward.cardID.capitalized)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("+\(reward.amount)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
