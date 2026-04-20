//
//  TeamCardPickerView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

struct TeamCardPickerView: View {
    let slotIndex: Int
    let onSelect: (AbilityCardDefinition) -> Void
    let onClose: () -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject private var gameState: GameState
    @Query(sort: \OwnedAbilityCard.acquiredAt) private var ownedCards:
        [OwnedAbilityCard]

    private var availableCards: [(AbilityCardDefinition, Int)] {
        ownedCards.compactMap { owned in
            guard
                let card = gameState.abilityCards.first(where: {
                    $0.id == owned.cardID
                })
            else { return nil }
            return (card, owned.count)
        }
    }

    var body: some View {

        VStack(spacing: 12) {
            header

            if availableCards.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 10
                    ) {
                        ForEach(availableCards, id: \.0.id) { card, count in
                            cardButton(card, count: count)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
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
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.48), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            VStack(spacing: 1) {
                Text("Skill Slot")
                    .font(.system(size: 26, weight: .light))
                Text("Slot \(slotIndex + 1)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.64))
            }
            .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 58)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 38, weight: .black))
            Text(
                "Keine Skill Cards. Ziehe Karten im Summon, dann kannst du sie hier einsetzen."
            )
            .font(.system(size: 14, weight: .black))
            .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardButton(_ card: AbilityCardDefinition, count: Int)
        -> some View
    {
        Button {
            onSelect(card)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                cardImage(card.image)
                    .frame(height: 164)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6).stroke(
                            .white.opacity(0.28),
                            lineWidth: 1
                        )
                    )

                Text(card.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                let level = cardLevel(card, count: count)
                let stars = cardStars(card, level: level)
                let damage = cardDamage(card, level: level, stars: stars)

                HStack {
                    Text(GameElement(card.element).displayName)
                        .foregroundStyle(GameElement(card.element).color)
                    Spacer()
                    Text("★\(stars) Lv.\(level)")
                    Text("x\(count)")
                }
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 8) {
                    Text("DMG x\(String(format: "%.2f", damage))")
                    Text("\(card.resolvedManaCost) MP")
                }
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.yellow)
            }
            .padding(8)
            .background(
                Color.black.opacity(0.42),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.black, Color(red: 0.12, green: 0.18, blue: 0.20),
                Color.black,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func cardLevel(_ card: AbilityCardDefinition, count: Int) -> Int {
        min(
            card.resolvedMaxLevel,
            1 + (max(1, count) - 1) / card.resolvedDuplicatesPerLevel
        )
    }

    private func cardStars(_ card: AbilityCardDefinition, level: Int) -> Int {
        min(card.resolvedMaxStars, 1 + (level - 1) / card.resolvedLevelsPerStar)
    }

    private func cardDamage(
        _ card: AbilityCardDefinition,
        level: Int,
        stars: Int
    ) -> Double {
        card.damageMultiplier
            * pow(card.resolvedDamageGrowth, Double(level - 1))
            * pow(1.12, Double(stars - 1))
    }

    @ViewBuilder
    private func cardImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.82), .cyan.opacity(0.36)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }
}
