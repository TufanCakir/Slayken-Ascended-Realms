//
//  SummonView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct SummonView: View {
    let banners: [SummonBanner]
    let characters: [SummonCharacter]
    let currencies: [CurrencyDefinition]
    var onClose: (() -> Void)? = nil

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var gameState: GameState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerCurrencyBalance.code) private var balances:
        [PlayerCurrencyBalance]
    @Query(sort: \OwnedSummonCharacter.acquiredAt) private var ownedRecords:
        [OwnedSummonCharacter]

    @State private var lastSummon: SummonDrop?
    @State private var lastBannerID: String?
    @State private var message = ""
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 18)

            centerBlock

            Spacer(minLength: 20)

            bannerBlock
                .padding(.horizontal, 20)

            Spacer(minLength: 18)
        }
        .background {
            ZStack {
                if let theme = themeManager.selectedTheme {
                    Image(theme.background)
                        .resizable()
                        .scaledToFill()
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

        .overlay {
            if showResult, let lastSummon {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    SummonResultView(result: lastSummon) {
                        withAnimation {
                            showResult = false
                        }
                    }
                }
            }
        }
        .onAppear {
            PlayerInventoryStore.ensureBalances(
                for: currencies,
                in: modelContext
            )
        }
    }

    private var bannerBlock: some View {
        VStack(spacing: 10) {
            ForEach(banners) { banner in
                summonBannerRow(banner)
                    .frame(maxWidth: .infinity)
            }

            if banners.isEmpty {
                emptyBannerState
            }
        }
        .padding(.vertical, 6)
    }

    private var centerBlock: some View {
        VStack(spacing: 12) {

            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.25))

            Text("Summon Portal")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.9))

            Text("Beschwoere neue Karten und Helden")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var header: some View {
        VStack(spacing: 10) {

            HStack {
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.48), in: Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 38, height: 38)
                }

                Spacer()

                Text("Summon Cards")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white.opacity(0.94))

                Spacer()

                Color.clear.frame(width: 38, height: 38)
            }
            .padding(.horizontal, 16)

            // 💰 HIER rein
            CurrencyBarView(currencies: currencies)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Color.black.opacity(0.35),
                    in: Capsule()
                )

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.horizontal, 62)
        }
        .padding(.top, 58)
    }

    private var background: some View {
        ZStack {
            Color(red: 0.12, green: 0.15, blue: 0.22)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color(red: 0.10, green: 0.13, blue: 0.20).opacity(0.92),
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image(systemName: "sparkles")
                .font(.system(size: 200, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.05))
                .offset(y: -120)
        }
    }

    private var emptyBannerState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white.opacity(0.72))
            Text("Keine Summon Banner")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func summonBannerRow(_ banner: SummonBanner) -> some View {
        let affordable = canAfford(banner.cost)
        let resultIsHere = lastBannerID == banner.id

        return ZStack {
            bannerBackground(banner.image)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.58),
                    Color.black.opacity(0.28),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            HStack(spacing: 9) {
                infoButton(banner)

                VStack(alignment: .leading, spacing: 3) {
                    Text(banner.name)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .shadow(color: .black, radius: 2, y: 1)

                    Text(bannerSubtitle(banner))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .shadow(color: .black, radius: 2, y: 1)

                    HStack(spacing: 8) {
                        Text(rateSummary(for: banner))
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.yellow)
                            .lineLimit(1)

                        if resultIsHere, let lastSummon {
                            Text(resultName(lastSummon))
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.green)
                                .lineLimit(1)
                        } else if !message.isEmpty, resultIsHere {
                            Text(message)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.red.opacity(0.92))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 4)

                VStack(spacing: 2) {
                    Button {
                        summon(from: banner)
                    } label: {
                        Text("Use")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 42)
                            .background(
                                LinearGradient(
                                    colors: affordable
                                        ? [
                                            Color(
                                                red: 0.10,
                                                green: 0.40,
                                                blue: 0.57
                                            ),
                                            Color(
                                                red: 0.05,
                                                green: 0.18,
                                                blue: 0.32
                                            ),
                                        ]
                                        : [
                                            Color.gray.opacity(0.62),
                                            Color.black.opacity(0.62),
                                        ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(.white.opacity(0.58), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!affordable)

                    Text(costText(banner.cost))
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(
                            affordable ? .white.opacity(0.9) : .red.opacity(0.9)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(width: 68)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
        }
        .frame(height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.38), radius: 8, y: 4)
    }

    private func infoButton(_ banner: SummonBanner) -> some View {
        Button {
            lastBannerID = banner.id
            lastSummon = nil
            message = poolText(for: banner)
        } label: {
            Text("Info")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(
                    RadialGradient(
                        colors: [
                            Color(red: 0.28, green: 0.66, blue: 0.78),
                            Color(red: 0.05, green: 0.18, blue: 0.28),
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 34
                    ),
                    in: Circle()
                )
                .overlay {
                    Circle().stroke(.white.opacity(0.56), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.45), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func summon(from banner: SummonBanner) {
        lastBannerID = banner.id
        lastSummon = nil

        guard PlayerInventoryStore.spend(banner.cost, in: modelContext) else {
            message = "Nicht genug Waehrung"
            return
        }

        guard
            let result = SummonService.summon(
                from: banner,
                characters: characters,
                cards: gameState.abilityCards
            )
        else {
            message = "Pool ist leer"
            return
        }

        switch result {
        case .character(let character):
            PlayerInventoryStore.addOwned(
                characterID: character.id,
                in: modelContext
            )
        case .card(let card):
            PlayerInventoryStore.addOwnedCard(cardID: card.id, in: modelContext)
        }

        lastSummon = result
        showResult = true
        message = ""
    }

    private func bannerSubtitle(_ banner: SummonBanner) -> String {
        let count = banner.pool.count
        if count == 1 {
            return "Summons 1 card from this banner."
        }
        return "Summons 1 card from a pool of \(count) drops."
    }

    private func rateSummary(for banner: SummonBanner) -> String {
        banner.rates
            .sorted { $0.rarity > $1.rarity }
            .map { "★\($0.rarity) \(String(format: "%.1f", $0.rate))%" }
            .joined(separator: "   ")
    }

    private func poolText(for banner: SummonBanner) -> String {
        banner.pool
            .compactMap { entry -> String? in
                if let characterID = entry.characterID {
                    return characters.first { $0.id == characterID }?.name
                }
                if let cardID = entry.cardID {
                    return gameState.abilityCards.first { $0.id == cardID }?
                        .name
                }
                return nil
            }
            .joined(separator: ", ")
    }

    private func resultName(_ result: SummonDrop) -> String {
        switch result {
        case .character(let character):
            return character.name
        case .card(let card):
            return card.name
        }
    }

    private func canAfford(_ cost: [CurrencyAmount]) -> Bool {
        cost.allSatisfy { costItem in
            amount(for: costItem.currency) >= costItem.amount
        }
    }

    private func amount(for code: String) -> Int {
        balances.first { $0.code == code }?.amount ?? 0
    }

    private func costText(_ cost: [CurrencyAmount]) -> String {
        cost.map { item in
            if let currency = currencies.first(where: {
                $0.code == item.currency
            }) {
                return "\(item.amount) \(currency.name)"
            }
            return "\(item.amount) \(item.currency)"
        }
        .joined(separator: " + ")
    }

    @ViewBuilder
    private func bannerBackground(_ imageName: String) -> some View {
        if UIImage(named: imageName) == nil {
            ZStack(alignment: .trailing) {
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.22, blue: 0.25),
                        Color(red: 0.55, green: 0.49, blue: 0.25),
                        Color(red: 0.05, green: 0.12, blue: 0.18),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                Image(systemName: "sparkles")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(.white.opacity(0.22))
                    .padding(.trailing, 76)
            }
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview {
    SummonView(banners: [], characters: [], currencies: [])
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
