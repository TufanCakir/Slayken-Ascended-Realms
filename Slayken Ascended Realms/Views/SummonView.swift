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
    @Query(sort: \SummonBannerProgress.bannerID) private var bannerProgress:
        [SummonBannerProgress]
    @Query private var accountProgress: [PlayerAccountProgress]

    @State private var lastSummon: SummonDrop?
    @State private var lastSummons: [SummonDrop] = []
    @State private var lastBannerID: String?
    @State private var message = ""
    @State private var showResult = false
    @State private var infoBanner: SummonBanner?
    @State private var confirmationBanner: SummonBanner?
    @State private var confirmationSummonCount = 1
    @State private var countdownNow = Date()

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    private var headerCurrencies: [CurrencyDefinition] {
        currencies.filter { ["coins", "crystals"].contains($0.code) }
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

        .overlay {
            if showResult, !lastSummons.isEmpty {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    SummonResultsView(results: lastSummons) {
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
        .task {
            while !Task.isCancelled {
                countdownNow = .now
                try? await Task.sleep(for: .seconds(30))
            }
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
            Button(
                summonButtonTitle(
                    count: confirmationSummonCount,
                    cost: totalCost(for: banner, count: confirmationSummonCount)
                )
            ) {
                performSummon(from: banner, count: confirmationSummonCount)
            }
            Button("Nicht summon", role: .cancel) {
                confirmationBanner = nil
                confirmationSummonCount = 1
            }
        } message: { banner in
            Text(
                "Willst du wirklich \(confirmationSummonCount)x \(banner.name) benutzen?"
            )
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

            CurrencyBarView(currencies: headerCurrencies, compact: true)

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
        let singleCost = totalCost(for: banner, count: 1)
        let multiCount = availableSummonCount(for: banner)
        let multiCost = totalCost(for: banner, count: multiCount)
        let affordable = canAfford(singleCost)
        let multiAffordable = canAfford(multiCost)
        let available = isAvailable(banner)
        let levelUnlocked = isLevelUnlocked(banner)
        let active = isDateActive(banner)
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

                        if let countdownText = countdownText(for: banner) {
                            Text(countdownText)
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.orange)
                                .lineLimit(1)
                        }

                        if resultIsHere, !lastSummons.isEmpty {
                            Text(resultSummary(lastSummons))
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

                VStack(spacing: 6) {
                    Button {
                        requestSummon(from: banner, count: 1)
                    } label: {
                        Text("Use")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 42)
                            .background(
                                LinearGradient(
                                    colors: affordable && available && active
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
                    .disabled(
                        !affordable || !available || !active || !levelUnlocked
                    )

                    if banner.resolvedMultiSummonCount > 1 {
                        Button {
                            requestSummon(from: banner, count: multiCount)
                        } label: {
                            Text("x\(multiCount)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 58, height: 28)
                                .background(
                                    multiAffordable && available && active
                                        && levelUnlocked && multiCount > 1
                                        ? Color.purple.opacity(0.78)
                                        : Color.gray.opacity(0.52),
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            .white.opacity(0.42),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .disabled(
                            !multiAffordable || !available || !active
                                || !levelUnlocked || multiCount <= 1
                        )
                    }

                    Text(costText(singleCost))
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(
                            affordable && available && active && levelUnlocked
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
        return summonButtonTitle(
            count: confirmationSummonCount,
            cost: totalCost(
                for: confirmationBanner,
                count: confirmationSummonCount
            )
        ) + "?"
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { confirmationBanner != nil },
            set: { isPresented in
                if !isPresented {
                    confirmationBanner = nil
                    confirmationSummonCount = 1
                }
            }
        )
    }

    private func requestSummon(from banner: SummonBanner, count: Int) {
        let resolvedCount = availableSummonCount(
            for: banner,
            requestedCount: count
        )
        lastBannerID = banner.id
        lastSummon = nil
        lastSummons = []

        guard isLevelUnlocked(banner) else {
            message =
                "Freischaltung ab Ascended Level \(banner.requiredAscendedLevel)"
            return
        }

        guard isDateActive(banner) else {
            message = "Banner beendet"
            return
        }

        guard isAvailable(banner) else {
            message = "Limit erreicht"
            return
        }

        guard resolvedCount > 0 else {
            message = "Limit erreicht"
            return
        }

        guard canAfford(totalCost(for: banner, count: resolvedCount)) else {
            message = "Nicht genug Waehrung"
            return
        }

        confirmationBanner = banner
        confirmationSummonCount = resolvedCount
    }

    private func performSummon(from banner: SummonBanner, count: Int) {
        confirmationBanner = nil
        lastBannerID = banner.id
        lastSummon = nil
        lastSummons = []

        let resolvedCount = availableSummonCount(
            for: banner,
            requestedCount: count
        )

        guard isLevelUnlocked(banner) else {
            message =
                "Freischaltung ab Ascended Level \(banner.requiredAscendedLevel)"
            return
        }

        guard isDateActive(banner) else {
            message = "Banner beendet"
            return
        }

        guard isAvailable(banner) else {
            message = "Limit erreicht"
            return
        }

        guard resolvedCount > 0 else {
            message = "Limit erreicht"
            return
        }

        let totalCost = totalCost(for: banner, count: resolvedCount)
        guard canAfford(totalCost) else {
            message = "Nicht genug Waehrung"
            return
        }

        let results = SummonService.summonMany(
            count: resolvedCount,
            from: banner,
            characters: characters,
            cards: gameState.abilityCards,
            startingSummonNumber: summonCount(for: banner) + 1
        )

        guard results.count == resolvedCount else {
            message = "Pool ist leer"
            return
        }

        guard PlayerInventoryStore.spend(totalCost, in: modelContext) else {
            message = "Nicht genug Waehrung"
            return
        }

        for result in results {
            switch result {
            case .character(let character):
                PlayerInventoryStore.addOwned(
                    characterID: character.id,
                    in: modelContext
                )
            case .skin(let characterID, let skin):
                PlayerInventoryStore.addOwnedSkin(
                    characterID: characterID,
                    skinID: skin.id,
                    in: modelContext
                )
            case .card(let card):
                PlayerInventoryStore.addOwnedCard(
                    cardID: card.id,
                    in: modelContext
                )
            }
        }

        PlayerInventoryStore.incrementSummonCount(
            for: banner.id,
            by: resolvedCount,
            in: modelContext
        )
        lastSummon = results.first
        lastSummons = results
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
        case .skin(_, let skin):
            return skin.name
        case .card(let card):
            return card.name
        }
    }

    private func resultSummary(_ results: [SummonDrop]) -> String {
        guard results.count > 1 else {
            return results.first.map(resultName) ?? ""
        }
        return "\(results.count)x Summon"
    }

    private func canAfford(_ cost: [CurrencyAmount]) -> Bool {
        cost.allSatisfy { costItem in
            amount(for: costItem.currency) >= costItem.amount
        }
    }

    private func totalCost(
        for banner: SummonBanner,
        count: Int
    ) -> [CurrencyAmount] {
        guard count > 1 else { return banner.cost }
        return banner.cost.map {
            CurrencyAmount(currency: $0.currency, amount: $0.amount * count)
        }
    }

    private func summonButtonTitle(
        count: Int,
        cost: [CurrencyAmount]
    ) -> String {
        if count > 1 {
            return "\(count)x Summon fuer \(costText(cost))"
        }
        return "Summon fuer \(costText(cost))"
    }

    private func summonCount(for banner: SummonBanner) -> Int {
        bannerProgress.first { $0.bannerID == banner.id }?.summonCount ?? 0
    }

    private func isAvailable(_ banner: SummonBanner) -> Bool {
        guard let maxSummons = banner.maxSummons else { return true }
        return summonCount(for: banner) < maxSummons
    }

    private func isDateActive(_ banner: SummonBanner) -> Bool {
        EventDateSupport.isActive(endsAt: banner.endsAt, now: countdownNow)
    }

    private func isLevelUnlocked(_ banner: SummonBanner) -> Bool {
        ascendedLevel >= banner.requiredAscendedLevel
    }

    private func limitText(for banner: SummonBanner) -> String? {
        guard let maxSummons = banner.maxSummons else { return nil }
        return "\(summonCount(for: banner))/\(maxSummons)"
    }

    private func countdownText(for banner: SummonBanner) -> String? {
        EventDateSupport.displayText(endsAt: banner.endsAt, now: countdownNow)
    }

    private func availableSummonCount(
        for banner: SummonBanner,
        requestedCount: Int? = nil
    ) -> Int {
        let requestedCount = max(
            1,
            requestedCount ?? banner.resolvedMultiSummonCount
        )
        guard let maxSummons = banner.maxSummons else {
            return requestedCount
        }
        let remaining = max(0, maxSummons - summonCount(for: banner))
        return min(requestedCount, remaining)
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
        RemoteAssetImage(imageName) {
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
        }
    }
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
                if banner.resolvedMultiSummonCount > 1 {
                    infoPill("Multi x\(banner.resolvedMultiSummonCount)")
                }
                if let maxSummons = banner.maxSummons {
                    infoPill("\(summonCount)/\(maxSummons) used")
                }
            }

            if let timingText = EventDateSupport.displayText(
                endsAt: banner.endsAt
            ) {
                Text(timingText)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.orange)
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
                    RemoteAssetImage(row.image, contentMode: .fill) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .foregroundStyle(.white.opacity(0.72))
                            .background(.white.opacity(0.08))
                    }
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
                let skinID = entry.skinID,
                let character = characters.first(where: { $0.id == characterID }
                ),
                let skin = character.skins.first(where: { $0.id == skinID })
            {
                return PoolRow(
                    id: "\(characterID):\(skin.id)",
                    name: skin.name,
                    image: skin.summonImage ?? character.summonImage,
                    kind: "Skin",
                    rarity: character.rarity,
                    weight: entry.weight
                )
            }

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
private struct SummonViewPreviewHost: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var gameState = GameState()
    @State private var didSeedPreviewData = false

    private let previewBanners = loadSummonBanners()
    private let previewCharacters = loadSummonCharacters()
    private let previewCurrencies = loadCurrencyDefinitions()

    var body: some View {
        SummonView(
            banners: previewBanners,
            characters: previewCharacters,
            currencies: previewCurrencies,
            onClose: {}
        )
        .environmentObject(themeManager)
        .environmentObject(gameState)
        .task {
            guard !didSeedPreviewData else { return }
            didSeedPreviewData = true
            seedPreviewData()
            gameState.reloadContent()
            themeManager.loadThemes()
            themeManager.loadSelected()
        }
    }

    private func seedPreviewData() {
        for (index, currency) in previewCurrencies.enumerated() {
            let amount = index == 0 ? 50_000 : 2_500
            modelContext.insert(
                PlayerCurrencyBalance(code: currency.code, amount: amount)
            )
        }

        modelContext.insert(PlayerAccountProgress(level: 12, xp: 480))

        if let firstBanner = previewBanners.first {
            modelContext.insert(
                SummonBannerProgress(
                    bannerID: firstBanner.id,
                    summonCount: 3
                )
            )
        }

        try? modelContext.save()
    }
}
