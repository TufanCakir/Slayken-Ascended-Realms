//
//  SummonView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

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
    @Query(sort: \SummonBannerProgress.bannerID) private var bannerProgress:
        [SummonBannerProgress]
    @Query private var accountProgress: [PlayerAccountProgress]

    @State private var lastSummon: SummonDrop?
    @State private var lastBannerID: String?
    @State private var message = ""
    @State private var showResult = false
    @State private var infoBanner: SummonBanner?
    @State private var confirmationBanner: SummonBanner?

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: true) {
                VStack(spacing: 18) {
                    centerBlock
                    bannerBlock
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .safeAreaPadding(.top, 6)
        .safeAreaPadding(.bottom, 6)
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
        .sheet(item: $infoBanner) { banner in
            SummonBannerInfoSheet(
                banner: banner,
                characters: characters,
                cards: gameState.abilityCards,
                currencies: currencies,
                summonCount: summonCount(for: banner),
                ascendedLevel: ascendedLevel
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: confirmationBinding,
            titleVisibility: .visible,
            presenting: confirmationBanner
        ) { banner in
            Button("Summon fuer \(costText(banner.cost))") {
                performSummon(from: banner)
            }
            Button("Nicht summon", role: .cancel) {
                confirmationBanner = nil
            }
        } message: { banner in
            Text("Willst du wirklich \(banner.name) benutzen?")
        }
    }

    private var bannerBlock: some View {
        LazyVStack(spacing: 12) {
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

            Text("Ascended Level \(ascendedLevel)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.cyan.opacity(0.9))
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

            }
            .padding(.horizontal)

            // 💰 HIER rein
            CurrencyBarView(currencies: currencies)

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.horizontal, 62)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
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
        let available = isAvailable(banner)
        let levelUnlocked = isLevelUnlocked(banner)
        let resultIsHere = lastBannerID == banner.id

        return ZStack {
            bannerBackground(banner.image)
                .allowsHitTesting(false)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.58),
                    Color.black.opacity(0.28),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .allowsHitTesting(false)

            HStack(spacing: 9) {
                infoButton(banner)

                VStack(alignment: .leading, spacing: 3) {
                    Text(banner.name)
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .shadow(color: .black, radius: 2, y: 1)

                    if let category = banner.category {
                        Text(category.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.cyan.opacity(0.95))
                            .lineLimit(1)
                    }

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

                        if !levelUnlocked {
                            Text("Unlock Lv. \(banner.requiredAscendedLevel)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.orange.opacity(0.95))
                                .lineLimit(1)
                        }

                        if let limitText = limitText(for: banner) {
                            Text(limitText)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)
                        }

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
                        requestSummon(from: banner)
                    } label: {
                        Text("Use")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 42)
                            .background(
                                LinearGradient(
                                    colors: affordable && available
                                        && levelUnlocked
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
                                    .stroke(.white.opacity(0.58), lineWidth: 2)
                            }
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .disabled(!affordable || !available || !levelUnlocked)

                    Text(costText(banner.cost))
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(
                            affordable && available && levelUnlocked
                                ? .white.opacity(0.9) : .red.opacity(0.9)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
        }
        .frame(height: 92)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
        .overlay {
            if !levelUnlocked {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.48))
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(.orange)
                            Text(
                                "Ab Ascended Level \(banner.requiredAscendedLevel)"
                            )
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                        }
                    }
            }
        }
        .shadow(color: .black.opacity(0.38), radius: 8, y: 4)
    }

    private func infoButton(_ banner: SummonBanner) -> some View {
        Button {
            infoBanner = banner
        } label: {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18, weight: .black))
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
        .contentShape(Circle())
    }

    private var confirmationTitle: String {
        guard let confirmationBanner else { return "Summon bestaetigen" }
        return "Summon fuer \(costText(confirmationBanner.cost))?"
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { confirmationBanner != nil },
            set: { isPresented in
                if !isPresented {
                    confirmationBanner = nil
                }
            }
        )
    }

    private func requestSummon(from banner: SummonBanner) {
        lastBannerID = banner.id
        lastSummon = nil

        guard isLevelUnlocked(banner) else {
            message =
                "Freischaltung ab Ascended Level \(banner.requiredAscendedLevel)"
            return
        }

        guard isAvailable(banner) else {
            message = "Limit erreicht"
            return
        }

        guard canAfford(banner.cost) else {
            message = "Nicht genug Waehrung"
            return
        }

        confirmationBanner = banner
    }

    private func performSummon(from banner: SummonBanner) {
        confirmationBanner = nil
        lastBannerID = banner.id
        lastSummon = nil

        guard isLevelUnlocked(banner) else {
            message =
                "Freischaltung ab Ascended Level \(banner.requiredAscendedLevel)"
            return
        }

        guard isAvailable(banner) else {
            message = "Limit erreicht"
            return
        }

        guard canAfford(banner.cost) else {
            message = "Nicht genug Waehrung"
            return
        }

        guard
            let result = SummonService.summon(
                from: banner,
                characters: characters,
                cards: gameState.abilityCards,
                summonNumber: summonCount(for: banner) + 1
            )
        else {
            message = "Pool ist leer"
            return
        }

        guard PlayerInventoryStore.spend(banner.cost, in: modelContext) else {
            message = "Nicht genug Waehrung"
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

        PlayerInventoryStore.incrementSummonCount(
            for: banner.id,
            in: modelContext
        )
        lastSummon = result
        showResult = true
        message = ""
    }

    private func bannerSubtitle(_ banner: SummonBanner) -> String {
        if let subtitle = banner.subtitle {
            return subtitle
        }
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

    private func summonCount(for banner: SummonBanner) -> Int {
        bannerProgress.first { $0.bannerID == banner.id }?.summonCount ?? 0
    }

    private func isAvailable(_ banner: SummonBanner) -> Bool {
        guard let maxSummons = banner.maxSummons else { return true }
        return summonCount(for: banner) < maxSummons
    }

    private func isLevelUnlocked(_ banner: SummonBanner) -> Bool {
        ascendedLevel >= banner.requiredAscendedLevel
    }

    private func limitText(for banner: SummonBanner) -> String? {
        guard let maxSummons = banner.maxSummons else { return nil }
        return "\(summonCount(for: banner))/\(maxSummons)"
    }

    private func amount(for code: String) -> Int {
        balances.first { $0.code == code }?.amount ?? 0
    }

    private func costText(_ cost: [CurrencyAmount]) -> String {
        guard !cost.isEmpty else { return "Free" }
        return cost.map { item in
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

#Preview("Summon Banners") {
    SummonView(
        banners: loadSummonBanners(),
        characters: loadSummonCharacters(),
        currencies: loadCurrencyDefinitions(),
        onClose: {}
    )
    .environmentObject(GameState())
    .environmentObject(ThemeManager())
    .modelContainer(
        for: [
            PlayerCurrencyBalance.self,
            OwnedSummonCharacter.self,
            OwnedAbilityCard.self,
            SummonBannerProgress.self,
        ],
        inMemory: true
    )
}

private struct SummonBannerInfoSheet: View {
    let banner: SummonBanner
    let characters: [SummonCharacter]
    let cards: [AbilityCardDefinition]
    let currencies: [CurrencyDefinition]
    let summonCount: Int
    let ascendedLevel: Int

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 18) {
                    bannerHero
                    ratesSection
                    guaranteeSection
                    poolSection
                }
                .padding(18)
            }
            .background(Color.black.opacity(0.92))
            .navigationTitle("Banner Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var bannerHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(banner.name)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let subtitle = banner.subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack(spacing: 8) {
                infoPill(banner.category ?? "Standard")
                infoPill(costText(banner.cost))
                infoPill("Asc Lv. \(banner.requiredAscendedLevel)")
                if let maxSummons = banner.maxSummons {
                    infoPill("\(summonCount)/\(maxSummons) used")
                }
            }

            if ascendedLevel < banner.requiredAscendedLevel {
                Text(
                    "Freigeschaltet ab Ascended Level \(banner.requiredAscendedLevel)"
                )
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var ratesSection: some View {
        infoSection(title: "Rates") {
            ForEach(banner.rates.sorted { $0.rarity > $1.rarity }) { rate in
                HStack {
                    Text(stars(rate.rarity))
                        .font(.system(size: 13, weight: .black))
                    Spacer()
                    Text("\(String(format: "%.1f", rate.rate))%")
                        .font(.system(size: 13, weight: .black))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 6)
            }
        }
    }

    @ViewBuilder
    private var guaranteeSection: some View {
        if let guarantee = banner.guarantee {
            infoSection(title: "Guarantee") {
                Text(guaranteeText(guarantee))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var poolSection: some View {
        infoSection(title: "Pool") {
            ForEach(poolRows, id: \.id) { row in
                HStack(spacing: 10) {
                    Image(row.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 42)
                        .clipped()
                        .background(.white.opacity(0.08))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                        Text("\(row.kind)  \(stars(row.rarity))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()

                    Text("W \(String(format: "%.0f", row.weight))")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.cyan.opacity(0.9))
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func infoSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.56))
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.white.opacity(0.12), in: Capsule())
    }

    private var poolRows: [PoolRow] {
        banner.pool.compactMap { entry in
            if let characterID = entry.characterID,
                let character = characters.first(where: { $0.id == characterID }
                )
            {
                return PoolRow(
                    id: character.id,
                    name: character.name,
                    image: character.summonImage,
                    kind: "Character",
                    rarity: character.rarity,
                    weight: entry.weight
                )
            }

            if let cardID = entry.cardID,
                let card = cards.first(where: { $0.id == cardID })
            {
                return PoolRow(
                    id: card.id,
                    name: card.name,
                    image: card.image,
                    kind: "Skill",
                    rarity: card.resolvedRarity,
                    weight: entry.weight
                )
            }

            return nil
        }
    }

    private func guaranteeText(_ guarantee: SummonGuarantee) -> String {
        let summonNumber = guarantee.appliesOnSummon ?? 1
        let type = guarantee.dropType ?? "drop"
        if let rarity = guarantee.rarity {
            return
                "On summon \(summonNumber), guarantees a \(stars(rarity)) \(type)."
        }
        return "On summon \(summonNumber), guarantees a \(type)."
    }

    private func costText(_ cost: [CurrencyAmount]) -> String {
        guard !cost.isEmpty else { return "Free" }
        return cost.map { item in
            let name =
                currencies.first { $0.code == item.currency }?.name
                ?? item.currency
            return "\(item.amount) \(name)"
        }
        .joined(separator: " + ")
    }

    private func stars(_ count: Int) -> String {
        String(repeating: "*", count: max(1, count))
    }

    private struct PoolRow {
        let id: String
        let name: String
        let image: String
        let kind: String
        let rarity: Int
        let weight: Double
    }
}
