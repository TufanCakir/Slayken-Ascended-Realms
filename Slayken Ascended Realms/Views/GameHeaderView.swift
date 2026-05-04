//
//  GameHeaderView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

private enum ResourceJumpDestination {
    case shop
    case quests
    case coop

    var buttonTitle: String {
        switch self {
        case .shop:
            "Zum Shop"
        case .quests:
            "Zu Quests"
        case .coop:
            "Im Coop farmen"
        }
    }
}

struct GameHeaderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerCurrencyBalance.code) private var currencyBalances:
        [PlayerCurrencyBalance]

    let playerName: String
    let playerPreviewImage: String?
    let currencies: [CurrencyDefinition]
    let ascendedLevel: Int
    let ascendedXP: Int
    let energy: Int?
    let maxEnergy: Int?
    let horizontalPadding: CGFloat
    let onOpenShop: () -> Void
    let onOpenQuests: () -> Void
    let onOpenCoop: () -> Void

    @State private var showResourceSheet = false

    init(
        playerName: String = "Adventurer",
        playerPreviewImage: String? = nil,
        currencies: [CurrencyDefinition] = [],
        ascendedLevel: Int = 1,
        ascendedXP: Int = 0,
        energy: Int? = nil,
        maxEnergy: Int? = nil,
        horizontalPadding: CGFloat = 20,
        onOpenShop: @escaping () -> Void = {},
        onOpenQuests: @escaping () -> Void = {},
        onOpenCoop: @escaping () -> Void = {}
    ) {
        self.playerName = playerName
        self.playerPreviewImage = playerPreviewImage
        self.currencies = currencies
        self.ascendedLevel = ascendedLevel
        self.ascendedXP = ascendedXP
        self.energy = energy
        self.maxEnergy = maxEnergy
        self.horizontalPadding = horizontalPadding
        self.onOpenShop = onOpenShop
        self.onOpenQuests = onOpenQuests
        self.onOpenCoop = onOpenCoop
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            topRow
            resourceHubButton
        }
        .padding(.horizontal, horizontalPadding)
        .sheet(isPresented: $showResourceSheet) {
            resourceSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var topRow: some View {
        HStack(alignment: .center, spacing: 14) {
            profileCluster
            visibleCurrencyStrip
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.38),
                    Color.black.opacity(0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
    }

    private var profileCluster: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.12),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let playerPreviewImage, !playerPreviewImage.isEmpty {
                    RemoteAssetImage(playerPreviewImage, contentMode: .fill) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)

                }
            }
            .frame(width: 38, height: 38)
            .padding(.top)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(playerName)
                        .font(
                            .system(size: 15, weight: .black, design: .rounded)
                        )
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("ST\(ascendedLevel)")
                        .font(
                            .system(size: 11, weight: .black, design: .rounded)
                        )
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.14))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.95),
                                            Color.cyan.opacity(0.82),
                                            Color.teal.opacity(0.62),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: proxy.size.width * xpProgress)
                        }
                    }
                    .frame(width: 130, height: 7)

                    Text("XP \(currentLevelXP)/\(xpRequiredForNextLevel)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                }

                if let energy, let maxEnergy, maxEnergy > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.orange)
                            Text("ENERGIE \(energy)/\(maxEnergy)")
                                .font(
                                    .system(
                                        size: 9,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.orange)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.orange.opacity(0.95),
                                                Color.yellow.opacity(0.82),
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: proxy.size.width * energyProgress
                                    )
                            }
                        }
                        .frame(width: 130, height: 7)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibleCurrencyStrip: some View {
        VStack(spacing: 7) {
            ForEach(headerVisibleCurrencies) { currency in
                headerCurrencyChip(currency)
            }
        }
    }

    private func headerCurrencyChip(_ currency: CurrencyDefinition) -> some View
    {
        HStack(spacing: 7) {
            currencyIcon(for: currency, size: 12)
            VStack(alignment: .leading, spacing: 1) {
                Text(currency.name.uppercased())
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(currencyAmount(for: currency.code))")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(minWidth: 52, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var resourceHubButton: some View {
        Button {
            showResourceSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.circle.fill")
                    .font(.system(size: 13, weight: .black))
                Text("Ressourcen anzeigen")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color.black.opacity(0.24),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private var resourceSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sortedCurrencies) { currency in
                        resourceSheetRow(currency)
                    }
                }
                .padding(20)
            }
            .background(
                Color.black.opacity(0.34),
                in: RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
                .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .navigationTitle("Ressourcen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func resourceSheetRow(_ currency: CurrencyDefinition) -> some View {
        let destinations = jumpDestinations(for: currency)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                currencyIcon(for: currency, size: 22)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(
                            .system(size: 17, weight: .black, design: .rounded)
                        )
                        .foregroundStyle(.white)
                    Text(resourceDescription(for: currency))
                        .font(
                            .system(size: 12, weight: .medium, design: .rounded)
                        )
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("\(currencyAmount(for: currency.code))")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            if !destinations.isEmpty {
                HStack(spacing: 8) {
                    ForEach(destinations, id: \.buttonTitle) { destination in
                        Button {
                            showResourceSheet = false
                            switch destination {
                            case .shop:
                                onOpenShop()
                            case .quests:
                                onOpenQuests()
                            case .coop:
                                onOpenCoop()
                            }
                        } label: {
                            Text(destination.buttonTitle)
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    buttonColor(for: destination),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.black.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func currencyIcon(for currency: CurrencyDefinition, size: CGFloat)
        -> some View
    {
        Group {
            if let assetIcon = currency.assetIcon, !assetIcon.isEmpty {
                RemoteAssetImage(assetIcon, contentMode: .fit) {
                    Image(systemName: currency.icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .padding(4)
                }
            } else {
                Image(systemName: currency.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .padding(4)
            }
        }
        .frame(width: size, height: size)
    }

    private var headerVisibleCurrencies: [CurrencyDefinition] {
        sortedCurrencies.filter { currency in
            currency.code == "coins" || currency.code == "crystals"
        }
    }

    private var sortedCurrencies: [CurrencyDefinition] {
        var definitionsByCode = [String: CurrencyDefinition]()

        for currency in currencies {
            definitionsByCode[currency.code] = currency
        }

        for currency in loadRaidCurrencyDefinitions() {
            definitionsByCode[currency.code] = currency
        }

        for balance in currencyBalances
        where definitionsByCode[balance.code] == nil {
            definitionsByCode[balance.code] = synthesizedCurrencyDefinition(
                for: balance.code
            )
        }

        return definitionsByCode.values.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.code < rhs.code
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func currencyAmount(for code: String) -> Int {
        PlayerInventoryStore.amount(for: code, in: modelContext)
    }

    private func resourceDescription(for currency: CurrencyDefinition) -> String
    {
        switch currency.code {
        case "coins":
            "Standardwährung für Upgrades, Käufe und allgemeine Fortschritte."
        case "crystals":
            "Premiumwährung für Banner, Shop-Angebote und seltene Freischaltungen."
        case "lava_sigil":
            "Coop-Beute aus Lava-Raids. Wird im Coop-Shop ausgegeben."
        case "moon_token":
            "Coop-Beute aus Mond-Raids. Wird für besondere Angebote gesammelt."
        case "void_core":
            "Spätere Coop-Währung aus Void-Raids für seltene Belohnungen."
        default:
            "Spezielle Ressource für Fortschritt, Käufe oder Event-Inhalte."
        }
    }

    private func synthesizedCurrencyDefinition(for code: String)
        -> CurrencyDefinition
    {
        switch code {
        case "lava_sigil":
            CurrencyDefinition(
                code: code,
                name: "Lava Sigil",
                icon: "flame.fill",
                assetIcon: "coop_coin_lava.png",
                sortOrder: 210
            )
        case "moon_token":
            CurrencyDefinition(
                code: code,
                name: "Moon Token",
                icon: "moon.stars.fill",
                assetIcon: "coop_coin_moon.png",
                sortOrder: 211
            )
        case "void_core":
            CurrencyDefinition(
                code: code,
                name: "Void Core",
                icon: "sparkles",
                assetIcon: "coop_coin_void.png",
                sortOrder: 212
            )
        default:
            CurrencyDefinition(
                code: code,
                name:
                    code
                    .split(separator: "_")
                    .map { $0.capitalized }
                    .joined(separator: " "),
                icon: "shippingbox.fill",
                assetIcon: nil,
                sortOrder: 900
            )
        }
    }

    private func jumpDestinations(for currency: CurrencyDefinition)
        -> [ResourceJumpDestination]
    {
        switch currency.code {
        case "coins", "crystals":
            return [.shop, .quests]
        case "lava_sigil", "moon_token", "void_core":
            return [.coop, .shop]
        default:
            return [.quests]
        }
    }

    private func buttonColor(for destination: ResourceJumpDestination) -> Color
    {
        switch destination {
        case .shop:
            return Color.blue.opacity(0.9)
        case .quests:
            return Color.green.opacity(0.9)
        case .coop:
            return Color.orange.opacity(0.9)
        }
    }

    private var xpRequiredForNextLevel: Int {
        PlayerInventoryStore.xpNeededForNextLevel(ascendedLevel)
    }

    private var currentLevelXP: Int {
        var remainingXP = max(0, ascendedXP)
        var level = 1

        while level < ascendedLevel {
            remainingXP -= PlayerInventoryStore.xpNeededForNextLevel(level)
            level += 1
        }

        return max(0, remainingXP)
    }

    private var xpProgress: CGFloat {
        guard xpRequiredForNextLevel > 0 else { return 0 }
        let progress = CGFloat(currentLevelXP) / CGFloat(xpRequiredForNextLevel)
        return min(max(progress, 0), 1)
    }

    private var energyProgress: CGFloat {
        guard let energy, let maxEnergy, maxEnergy > 0 else { return 0 }
        let progress = CGFloat(energy) / CGFloat(maxEnergy)
        return min(max(progress, 0), 1)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.32, blue: 0.60),
                Color(red: 0.04, green: 0.10, blue: 0.20),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 0) {
            GameHeaderView(
                playerName: "Tufan",
                playerPreviewImage: "preview_shen",
                currencies: loadCurrencyDefinitions()
                    + loadRaidCurrencyDefinitions(),
                ascendedLevel: 12,
                ascendedXP: 3200,
                energy: 18,
                maxEnergy: 20
            )
            .padding(.top, 10)

            Spacer()
        }
    }
    .frame(width: 393, height: 180, alignment: .top)
    .environmentObject(RemoteContentManager.shared)
    .modelContainer(for: [PlayerCurrencyBalance.self], inMemory: true)
    .preferredColorScheme(.dark)
}
