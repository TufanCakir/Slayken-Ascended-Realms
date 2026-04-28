//
//  GameHeaderView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameHeaderView: View {
    let currencies: [CurrencyDefinition]
    let ascendedLevel: Int
    let ascendedXP: Int
    private let horizontalPadding: CGFloat

    init(
        currencies: [CurrencyDefinition] = [],
        ascendedLevel: Int = 1,
        ascendedXP: Int = 0,
        horizontalPadding: CGFloat = 34,
        onNews: @escaping () -> Void = {}
    ) {
        self.currencies = currencies
        self.ascendedLevel = ascendedLevel
        self.ascendedXP = ascendedXP
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        topRow
            .padding(.horizontal, horizontalPadding)
        xpProgressBar
            .padding()
    }

    private var topRow: some View {
        HStack(spacing: 100) {
            ascendedBadge
            resourceControls
        }
    }

    private var resourceControls: some View {
        CurrencyBarView(currencies: currencies, compact: true)
    }

    private var xpProgressBar: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Text("Ascended XP")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))

                Text("\(currentLevelXP)/\(xpRequiredForNextLevel)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.18))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.95),
                                    Color.orange.opacity(0.92),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * xpProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.38), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
    }

    private var ascendedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 1) {
                Text("ASCENDED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.66))
                Text("Lv. \(ascendedLevel)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.42), in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
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
}

#Preview {
    GameHeaderView(
        currencies: loadCurrencyDefinitions(),
        ascendedLevel: 12,
        ascendedXP: 3200
    )
}
