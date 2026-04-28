//
//  ShopView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct ShopView: View {
    private enum ShopCategory: String, CaseIterable, Identifiable {
        case all = "Alles"
        case resources = "Ressourcen"
        case skins = "Skins"
        case crystals = "Echtgeld"

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager

    @Query(sort: \ShopOfferProgress.offerID) private var offerProgress:
        [ShopOfferProgress]
    @Query(sort: \OwnedCharacterSkin.id) private var ownedSkins:
        [OwnedCharacterSkin]

    let onClose: () -> Void

    @StateObject private var storeKitManager = StoreKitShopManager()
    @State private var message = ""
    @State private var selectedCategory: ShopCategory = .all

    private let shopOffers = loadShopOffers()
    private let skinOffers = loadShopSkinOffers()
    private let crystalPacks = loadStoreCrystalPacks()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    GameHeaderView(
                        currencies: gameState.currencies,
                        ascendedLevel: ascendedLevel
                    )
                    heroSection
                    categoryBar
                    filteredSections
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.45), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            PlayerInventoryStore.ensureBalances(
                for: gameState.currencies,
                in: modelContext
            )
            storeKitManager.configure(
                packs: crystalPacks,
                contextProvider: { modelContext }
            )
            await storeKitManager.loadProducts()
        }
    }

    private var ascendedLevel: Int {
        PlayerInventoryStore.accountProgress(in: modelContext).level
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shop")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text(
                "Kaufe Ressourcen mit Coins, Crystals oder beidem, sichere dir Skins und lade Echtgeld-Crystals ueber StoreKit nach."
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.82))

            if !resolvedMessage.isEmpty {
                Text(resolvedMessage)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.cyan.opacity(0.95))
            }
        }
    }

    private var offersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Ressourcen")
            ForEach(shopOffers) { offer in
                shopOfferCard(offer)
            }
        }
    }

    private var skinsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Skins")
            if skinOffers.isEmpty {
                unavailableSkinsNotice
            } else {
                ForEach(skinOffers) { offer in
                    skinOfferCard(offer)
                }
            }
        }
    }

    private var crystalPacksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Echtgeld Crystals")

            ForEach(crystalPacks) { pack in
                crystalPackCard(pack)
            }
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ShopCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(
                                selectedCategory == category
                                    ? .black : .white
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                    ? Color.yellow
                                    : Color.black.opacity(0.32),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        .white.opacity(
                                            selectedCategory == category
                                                ? 0 : 0.10
                                        ),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var filteredSections: some View {
        switch selectedCategory {
        case .all:
            offersSection
            skinsSection
            crystalPacksSection
        case .resources:
            offersSection
        case .skins:
            skinsSection
        case .crystals:
            crystalPacksSection
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white)
    }

    private func shopOfferCard(_ offer: ShopOfferDefinition) -> some View {
        let purchaseCount =
            offerProgress.first(where: { $0.offerID == offer.id })?
            .purchaseCount ?? 0
        let soldOut = !isAvailable(
            maxPurchases: offer.maxPurchases,
            count: purchaseCount
        )
        let canBuy =
            canAfford(offer.cost)
            && !soldOut

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                offerImage(offer.image)

                VStack(alignment: .leading, spacing: 6) {
                    Text(offer.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    if let subtitle = offer.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    if let category = offer.category {
                        tag(category)
                    }
                }
                Spacer()
            }

            Text("Belohnung: \(rewardsText(offer.rewards))")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.9))

            HStack(spacing: 10) {
                tag(costText(offer.cost))
                if let maxPurchases = offer.maxPurchases {
                    tag("\(purchaseCount)/\(maxPurchases)")
                }
                Spacer()

                Button {
                    buy(offer)
                } label: {
                    Text(
                        buttonTitle(
                            canBuy: canBuy,
                            isFree: offer.cost.isEmpty,
                            soldOut: soldOut
                        )
                    )
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(canBuy ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        canBuy ? Color.yellow : Color.gray.opacity(0.38)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canBuy)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func skinOfferCard(_ offer: ShopSkinOfferDefinition) -> some View {
        let owned = ownedSkins.contains {
            $0.characterID == offer.characterID && $0.skinID == offer.skinID
        }
        let purchaseCount =
            offerProgress.first(where: { $0.offerID == offer.id })?
            .purchaseCount ?? 0
        let soldOut = !isAvailable(
            maxPurchases: offer.maxPurchases,
            count: purchaseCount
        )
        let canBuy =
            !owned
            && canAfford(offer.cost)
            && !soldOut

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                offerImage(offer.image)

                VStack(alignment: .leading, spacing: 6) {
                    Text(offer.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    if let subtitle = offer.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    tag("Skin")
                }
                Spacer()
            }

            HStack(spacing: 10) {
                tag(costText(offer.cost))
                if owned {
                    tag("Owned")
                }
                if let maxPurchases = offer.maxPurchases {
                    tag("\(purchaseCount)/\(maxPurchases)")
                }
                Spacer()

                Button {
                    buySkin(offer)
                } label: {
                    Text(
                        owned
                            ? "Bereits gekauft"
                            : (soldOut
                                ? "Ausverkauft"
                                : (canBuy ? "Skin kaufen" : "Nicht genug"))
                    )
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(canBuy ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        canBuy ? Color.yellow : Color.gray.opacity(0.38)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canBuy)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func crystalPackCard(_ pack: StoreCrystalPackDefinition)
        -> some View
    {
        let inFlight =
            storeKitManager.purchaseInFlightProductID == pack.productID

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                offerImage(pack.image)

                VStack(alignment: .leading, spacing: 6) {
                    Text(pack.name)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                    if let subtitle = pack.subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    Text("Enthaelt: \(packRewardsText(pack))")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.cyan.opacity(0.94))
                }
                Spacer()
            }

            HStack {
                tag(storeKitManager.displayPrice(for: pack))
                Spacer()

                Button {
                    Task {
                        await buyCrystalPack(pack)
                    }
                } label: {
                    Text(inFlight ? "Kauft..." : "Mit Echtgeld kaufen")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.92))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(inFlight || storeKitManager.product(for: pack) == nil)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var unavailableSkinsNotice: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.yellow)
                .frame(width: 50, height: 50)
                .background(
                    Color.white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text("Skins noch nicht verfügbar")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)

                Text(
                    "Charakter-Skins werden später hinzugefügt. Aktuell sind in diesem Shopbereich noch keine Skins verfügbar."
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.black.opacity(0.34))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func offerImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.16),
                            Color.black.opacity(0.32),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .overlay {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white.opacity(0.68))
                }
        }
    }

    private func tag(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12), in: Capsule())
    }

    private var resolvedMessage: String {
        storeKitManager.message.isEmpty ? message : storeKitManager.message
    }

    private var backgroundView: some View {
        ZStack {
            if let selectedTheme = theme.selectedTheme {
                Image(selectedTheme.background)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.70),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private func buy(_ offer: ShopOfferDefinition) {
        let count = PlayerInventoryStore.shopPurchaseCount(
            for: offer.id,
            in: modelContext
        )
        guard isAvailable(maxPurchases: offer.maxPurchases, count: count) else {
            message = "Limit erreicht."
            return
        }
        guard PlayerInventoryStore.canSpend(offer.cost, in: modelContext) else {
            message = "Nicht genug Waehrung."
            return
        }
        guard PlayerInventoryStore.spend(offer.cost, in: modelContext) else {
            message = "Nicht genug Waehrung."
            return
        }

        PlayerInventoryStore.add(offer.rewards, in: modelContext)
        PlayerInventoryStore.incrementShopPurchaseCount(
            for: offer.id,
            in: modelContext
        )
        message = "\(offer.name) gekauft."
    }

    private func buySkin(_ offer: ShopSkinOfferDefinition) {
        let count = PlayerInventoryStore.shopPurchaseCount(
            for: offer.id,
            in: modelContext
        )
        guard isAvailable(maxPurchases: offer.maxPurchases, count: count) else {
            message = "Limit erreicht."
            return
        }
        guard
            !PlayerInventoryStore.ownsSkin(
                characterID: offer.characterID,
                skinID: offer.skinID,
                in: modelContext
            )
        else {
            message = "Skin bereits vorhanden."
            return
        }
        guard PlayerInventoryStore.canSpend(offer.cost, in: modelContext) else {
            message = "Nicht genug Waehrung."
            return
        }
        guard PlayerInventoryStore.spend(offer.cost, in: modelContext) else {
            message = "Nicht genug Waehrung."
            return
        }

        PlayerInventoryStore.addOwnedSkin(
            characterID: offer.characterID,
            skinID: offer.skinID,
            in: modelContext
        )
        PlayerInventoryStore.incrementShopPurchaseCount(
            for: offer.id,
            in: modelContext
        )
        message = "\(offer.name) freigeschaltet."
    }

    private func buyCrystalPack(_ pack: StoreCrystalPackDefinition) async {
        _ = await storeKitManager.purchase(pack)
    }

    private func rewardsText(_ rewards: [CurrencyAmount]) -> String {
        rewards.map { reward in
            let currencyName =
                gameState.currencies.first(where: { $0.code == reward.currency }
                )?.name
                ?? reward.currency
            return "\(reward.amount) \(currencyName)"
        }
        .joined(separator: " + ")
    }

    private func packRewardsText(_ pack: StoreCrystalPackDefinition) -> String {
        var parts: [String] = []

        if !pack.rewards.isEmpty {
            parts.append(rewardsText(pack.rewards))
        }

        for characterReward in pack.characterRewards {
            let name =
                gameState.summonCharacters.first(where: {
                    $0.id == characterReward.characterID
                })?.name ?? characterReward.characterID
            parts.append("Charakter \(name)")
        }

        for skinReward in pack.skinRewards {
            let characterName =
                gameState.summonCharacters.first(where: {
                    $0.id == skinReward.characterID
                })?.name ?? skinReward.characterID
            parts.append("Skin \(characterName): \(skinReward.skinID)")
        }

        for cardReward in pack.cardRewards {
            let cardName =
                loadAbilityCards().first(where: { $0.id == cardReward.cardID })?
                .name
                ?? cardReward.cardID
            parts.append("\(cardReward.amount)x Karte \(cardName)")
        }

        return parts.joined(separator: " + ")
    }

    private func costText(_ cost: [CurrencyAmount]) -> String {
        guard !cost.isEmpty else { return "Kostenlos" }
        return rewardsText(cost)
    }

    private func canAfford(_ cost: [CurrencyAmount]) -> Bool {
        PlayerInventoryStore.canSpend(cost, in: modelContext)
    }

    private func isAvailable(maxPurchases: Int?, count: Int) -> Bool {
        guard let maxPurchases else { return true }
        return count < maxPurchases
    }

    private func buttonTitle(canBuy: Bool, isFree: Bool, soldOut: Bool)
        -> String
    {
        if soldOut {
            return "Ausverkauft"
        }
        if canBuy {
            return isFree ? "Gratis holen" : "Kaufen"
        }
        return "Nicht genug"
    }
}

#Preview {
    ShopView(onClose: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
