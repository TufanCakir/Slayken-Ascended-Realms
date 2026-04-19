import SwiftData
import SwiftUI
import UIKit

struct CardCollectionView: View {
    let onClose: () -> Void

    @EnvironmentObject private var gameState: GameState
    @Query(sort: \OwnedAbilityCard.acquiredAt) private var ownedCards: [OwnedAbilityCard]

    private var cards: [(AbilityCardDefinition, Int)] {
        ownedCards.compactMap { owned in
            guard let card = gameState.abilityCards.first(where: { $0.id == owned.cardID }) else { return nil }
            return (card, owned.count)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.10, green: 0.14, blue: 0.16), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(cards, id: \.0.id) { card, count in
                                cardView(card, count: count)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }

    private func cardView(_ card: AbilityCardDefinition, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            cardImage(card.image)
                .frame(height: 178)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

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

            Text(card.description)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(2)
        }
        .padding(8)
        .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.16), lineWidth: 1))
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
