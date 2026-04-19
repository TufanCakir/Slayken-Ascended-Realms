import SwiftData
import SwiftUI
import UIKit

struct TeamCardPickerView: View {
    let slotIndex: Int
    let onSelect: (AbilityCardDefinition) -> Void
    let onClose: () -> Void

    @EnvironmentObject private var gameState: GameState
    @Query(sort: \OwnedAbilityCard.acquiredAt) private var ownedCards: [OwnedAbilityCard]

    private var availableCards: [(AbilityCardDefinition, Int)] {
        ownedCards.compactMap { owned in
            guard let card = gameState.abilityCards.first(where: { $0.id == owned.cardID }) else { return nil }
            return (card, owned.count)
        }
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 12) {
                header

                if availableCards.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(availableCards, id: \.0.id) { card, count in
                                cardButton(card, count: count)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
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
            Text("Keine Skill Cards. Ziehe Karten im Summon, dann kannst du sie hier einsetzen.")
                .font(.system(size: 14, weight: .black))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardButton(_ card: AbilityCardDefinition, count: Int) -> some View {
        Button {
            onSelect(card)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                cardImage(card.image)
                    .frame(height: 164)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.28), lineWidth: 1))

                Text(card.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack {
                    Text(card.element)
                    Spacer()
                    Text("x\(count)")
                }
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.72))

                Text("DMG x\(String(format: "%.2f", card.damageMultiplier))")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.yellow)
            }
            .padding(8)
            .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        LinearGradient(colors: [Color.black, Color(red: 0.12, green: 0.18, blue: 0.20), Color.black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private func cardImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(colors: [.black.opacity(0.82), .cyan.opacity(0.36)], startPoint: .top, endPoint: .bottom)
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }
}
