//
//  CardCollectionView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

private struct SelectedCardInfo: Identifiable {
    let card: AbilityCardDefinition
    let count: Int

    var id: String { card.id }
}

struct CardCollectionView: View {
    let onClose: () -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject private var gameState: GameState
    @Query(sort: \OwnedAbilityCard.acquiredAt) private var ownedCards:
        [OwnedAbilityCard]
    @State private var selectedInfoCard: SelectedCardInfo?

    private var cards: [(AbilityCardDefinition, Int)] {
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
                Text("Meine Karten")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.white)
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
            .padding(.horizontal, 16)
            .padding(.top, 58)

            if cards.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 40, weight: .black))
                    Text("Noch keine Karten gezogen")
                        .font(.system(size: 15, weight: .black))
                }
                .foregroundStyle(.white.opacity(0.76))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                        ],
                        spacing: 10
                    ) {
                        ForEach(cards, id: \.0.id) { card, count in
                            cardView(card, count: count)
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
        .sheet(item: $selectedInfoCard) { entry in
            CardInfoSheet(
                card: entry.card,
                count: entry.count,
                level: cardLevel(entry.card, count: entry.count),
                stars: cardStars(
                    entry.card,
                    level: cardLevel(entry.card, count: entry.count)
                ),
                damage: cardDamage(
                    entry.card,
                    level: cardLevel(entry.card, count: entry.count),
                    stars: cardStars(
                        entry.card,
                        level: cardLevel(entry.card, count: entry.count)
                    )
                )
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func cardView(_ card: AbilityCardDefinition, count: Int)
        -> some View
    {
        let level = cardLevel(card, count: count)
        let stars = cardStars(card, level: level)
        let damage = cardDamage(card, level: level, stars: stars)

        return VStack(alignment: .leading, spacing: 7) {
            ZStack(alignment: .topTrailing) {
                cardImage(card.image)
                    .frame(height: 178)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )

                Button {
                    selectedInfoCard = SelectedCardInfo(
                        card: card,
                        count: count
                    )
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            HStack(spacing: 8) {
                Text(card.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(card.isAOE ? "AOE" : "Single")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12), in: Capsule())
            }

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
            .foregroundStyle(.cyan.opacity(0.86))

            Text(card.description)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(2)
        }
        .padding(8)
        .background(
            Color.black.opacity(0.42),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(
                .white.opacity(0.16),
                lineWidth: 1
            )
        )
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

private struct CardInfoSheet: View {
    let card: AbilityCardDefinition
    let count: Int
    let level: Int
    let stars: Int
    let damage: Double

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                infoRow("Element", GameElement(card.element).displayName)
                infoRow("Ziel", card.isAOE ? "Alle Gegner" : "Ein Gegner")
                infoRow("Mana", "\(card.resolvedManaCost) MP")
                infoRow("Level", "\(level) / \(card.resolvedMaxLevel)")
                infoRow("Sterne", "\(stars) / \(card.resolvedMaxStars)")
                infoRow("Besitz", "x\(count)")
                infoRow("DMG", "x\(String(format: "%.2f", damage))")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Beschreibung")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(card.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(18)
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.94), Color.cyan.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if UIImage(named: card.image) != nil {
                    Image(card.image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [
                                .black.opacity(0.82), .cyan.opacity(0.36),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Image(systemName: "sparkles")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(card.name)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

#Preview {
    CardCollectionView(onClose: {})
        .environmentObject(ThemeManager())
}
