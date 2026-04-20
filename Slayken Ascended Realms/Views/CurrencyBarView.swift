//
//  CurrencyBarView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct CurrencyBarView: View {
    let currencies: [CurrencyDefinition]
    var compact = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlayerCurrencyBalance.code) private var balances:
        [PlayerCurrencyBalance]

    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            ForEach(currencies) { currency in
                currencyChip(currency)
            }
        }
        .onAppear {
            PlayerInventoryStore.ensureBalances(
                for: currencies,
                in: modelContext
            )
        }
    }

    private func currencyChip(_ currency: CurrencyDefinition) -> some View {
        HStack(spacing: compact ? 4 : 6) {
            currencyIcon(currency)
                .frame(width: compact ? 14 : 18, height: compact ? 14 : 18)

            Text("\(amount(for: currency.code))")
                .font(.system(size: compact ? 11 : 12, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(Color.black.opacity(0.62), in: Capsule())
    }

    @ViewBuilder
    private func currencyIcon(_ currency: CurrencyDefinition) -> some View {
        if let assetIcon = currency.assetIcon, UIImage(named: assetIcon) != nil
        {
            Image(assetIcon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: currency.icon)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.92))
        }
    }

    private func amount(for code: String) -> Int {
        balances.first { $0.code == code }?.amount ?? 0
    }
}
