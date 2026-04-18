//
//  GameHeaderView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 17.04.26.
//

import SwiftUI

struct GameHeaderView: View {
    let currencies: [CurrencyDefinition]

    @State private var isExpanded = true

    init(currencies: [CurrencyDefinition] = []) {
        self.currencies = currencies
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)

            CurrencyBarView(currencies: currencies, compact: true)
                .frame(width: isExpanded ? currencyWidth : 0, alignment: .trailing)
                .clipped()
                .opacity(isExpanded ? 1 : 0)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: 34, height: 38)
                    .background(.white.opacity(0.92), in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Hide Resources" : "Show Resources")
        }
        .padding(.horizontal, 14)
        .padding(.top, 58)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: isExpanded)
    }

    private var currencyWidth: CGFloat {
        let count = max(currencies.count, 1)
        return CGFloat(min(count, 4) * 76 + max(0, min(count, 4) - 1) * 6)
    }
}

#Preview {
    GameHeaderView()
}
