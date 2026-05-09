//
//  BattleInfoPopupView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct BattleInfoPopupView: View {
    @Binding var showPopup: Bool

    let battle: GlobeBattle
    let onStart: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager
    @Query(sort: \PlayerDeckCardSlot.slotIndex) private var deckSlots:
        [PlayerDeckCardSlot]
    @Query(sort: \OwnedAbilityCard.cardID) private var ownedCards:
        [OwnedAbilityCard]

    private var mainEnemy: CharacterStats {
        battle.primaryEnemy
    }

    private var enemyElement: GameElement {
        GameElement(mainEnemy.element)
    }

    private var playerElement: GameElement {
        GameElement(gameState.player.element)
    }

    private var enemyLevel: Int {
        max(1, battle.difficulty * 5 + enemyCount * 2)
    }

    private var enemyStars: Int {
        min(5, max(1, battle.difficulty + (battle.boss == nil ? 0 : 1)))
    }

    private var enemyPower: Int {
        Int((mainEnemy.hp + mainEnemy.attack * 10).rounded())
    }

    private var enemyCount: Int {
        battle.battleEnemies.count
    }

    private var staminaCost: Int {
        PlayerInventoryStore.dailyBattleFarmStatus(in: modelContext)
            .energyCostPerBattle
    }

    private var activeCards: [AbilityCardDefinition] {
        let slotLimit = loadDeckConfiguration().resolvedSlotCount
        return
            deckSlots
            .sorted { $0.slotIndex < $1.slotIndex }
            .prefix(slotLimit)
            .compactMap { slot in
                gameState.abilityCards.first { $0.id == slot.cardID }
            }
    }

    private var deckSlotCount: Int {
        max(loadDeckConfiguration().resolvedSlotCount, 1)
    }

    private var recommendedElements: [GameElement] {
        GameElement.allCases.filter { element in
            element.multiplier(against: enemyElement) > 1.0
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar

                VStack(alignment: .leading, spacing: 10) {
                    informationSection
                    bonusSection
                    warningSection
                    deckSection
                    actionStack
                }
                .padding(12)
            }
            .frame(maxWidth: 360)
            .background(panelBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.cyan.opacity(0.24), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.62), radius: 24, y: 10)
            .padding(.horizontal, 14)
        }
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.025, green: 0.105, blue: 0.205).opacity(0.98),
                Color(red: 0.018, green: 0.065, blue: 0.145).opacity(0.99),
                Color(red: 0.008, green: 0.028, blue: 0.075).opacity(0.99),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18, weight: .black))

            Text(battle.name)
                .font(.system(size: 25, weight: .light, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.24, blue: 0.44).opacity(0.96),
                    Color(red: 0.03, green: 0.13, blue: 0.29).opacity(0.96),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Information")

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    infoRow(
                        icon: nil,
                        title: "Stamina",
                        value: "\(staminaCost)"
                    )
                    infoRow(
                        icon: nil,
                        title: "Battles",
                        value: "\(enemyCount)"
                    )
                }

                Spacer(minLength: 0)

                enemyPortrait
            }
            .padding(8)
            .background(sectionBackground)
        }
    }

    private var enemyPortrait: some View {
        VStack(spacing: 4) {
            RemoteAssetImage(
                battle.resolvedNodeImage(
                    defaultImage: gameState.activeEventChapter?.nodeImage
                ),
                contentMode: .fit
            ) {
                RemoteAssetImage(mainEnemy.image, contentMode: .fill) {
                    Color.black.opacity(0.30)
                }
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(enemyElement.color.opacity(0.9), lineWidth: 2)
            }

            Text(enemyElement.displayName)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(enemyElement.color)
        }
    }

    private var bonusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Bonuses")

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white)
                    Text("Rewards")
                    Text("x 1.0")
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    difficultyStars
                }
                .font(.system(size: 12, weight: .black))
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(
                    rowBackground,
                    in: RoundedRectangle(cornerRadius: 5)
                )

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.square.fill")
                        .foregroundStyle(.mint)
                    Text("EXP")
                        .foregroundStyle(.red.opacity(0.95))
                    Text("x 1.0")
                        .foregroundStyle(.mint)
                    Spacer()
                    Text("First Clear")
                        .font(
                            .system(size: 18, weight: .light, design: .rounded)
                        )
                        .foregroundStyle(.white.opacity(0.22))
                }
                .font(.system(size: 12, weight: .black))
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.28, blue: 0.42).opacity(
                                0.92
                            ),
                            Color(red: 0.02, green: 0.14, blue: 0.28).opacity(
                                0.92
                            ),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 5)
                )
            }
        }
    }

    private var difficultyStars: some View {
        HStack(spacing: 1) {
            Text("Difficulty")
                .foregroundStyle(.white)
                .padding(.trailing, 2)

            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(
                        index < enemyStars ? .yellow : .white.opacity(0.32)
                    )
            }
        }
    }

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Warnings")

            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.square.fill")
                    .foregroundStyle(.white)

                Text(warningText)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(9)
            .background(sectionBackground)
        }
    }

    private var warningText: String {
        if battle.boss != nil {
            return "\(enemyElement.displayName) boss sighted."
        }

        return "\(enemyElement.displayName) enemies sighted."
    }

    private var deckSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                sectionLabel("Select Deck")
                Spacer()
                Text("\(gameState.player.name)  Lv. 1")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.76))
            }

            HStack(spacing: 6) {
                Text("Elements")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.74))

                elementChip(playerElement)

                ForEach(recommendedElements.prefix(3), id: \.self) { element in
                    elementChip(element)
                }

                Spacer()
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 5)
            )

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Job")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.86))
                    characterCard
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Abilities")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.86))

                    HStack(spacing: 6) {
                        ForEach(0..<deckSlotCount, id: \.self) { index in
                            if activeCards.indices.contains(index) {
                                abilityCard(activeCards[index])
                            } else {
                                emptyCardSlot(index + 1)
                            }
                        }
                    }
                }
            }
            .padding(8)
            .background(sectionBackground)

            Text("Decks 1/3")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity)
        }
    }

    private var characterCard: some View {
        RemoteAssetImage(gameState.player.image, contentMode: .fill) {
            Image(systemName: "person.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.28))
        }
        .frame(width: 62, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(playerElement.color.opacity(0.9), lineWidth: 2)
        }
    }

    private func abilityCard(_ card: AbilityCardDefinition) -> some View {
        let progress = cardProgress(for: card)
        let element = GameElement(card.element)

        return ZStack(alignment: .bottomTrailing) {
            RemoteAssetImage(card.image, contentMode: .fill) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.30))
            }
            .frame(width: 48, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(element.color.opacity(0.95), lineWidth: 2)
            }

            VStack(alignment: .trailing, spacing: 0) {
                Text("L\(progress.level)")
                Text("\(card.resolvedManaCost)")
            }
            .font(.system(size: 7, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Color.black.opacity(0.72),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .padding(3)
        }
    }

    private func emptyCardSlot(_ index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.28))
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
            Text("\(index)")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.30))
        }
        .frame(width: 48, height: 62)
    }

    private var actionStack: some View {
        VStack(spacing: 8) {

            Button {
                showPopup = false
                onStart()
            } label: {
                Text("Starten")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.25, blue: 0.55)
                                    .opacity(0.96),
                                Color(red: 0.02, green: 0.14, blue: 0.34)
                                    .opacity(0.96),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 4,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                showPopup = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.04, green: 0.18, blue: 0.36)
                                    .opacity(0.86),
                                Color(red: 0.02, green: 0.10, blue: 0.24)
                                    .opacity(0.92),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 4,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
    }

    private var sectionBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.25, blue: 0.42).opacity(0.45),
                Color(red: 0.01, green: 0.04, blue: 0.12).opacity(0.72),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var rowBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.08, blue: 0.18).opacity(0.88),
                Color(red: 0.00, green: 0.03, blue: 0.09).opacity(0.92),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.white.opacity(0.68))
    }

    private func infoRow(icon: String?, title: String, value: String)
        -> some View
    {
        HStack(spacing: 8) {
            Group {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                } else {
                    Color.clear
                }
            }
            .frame(width: 18, height: 18)

            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(":")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white.opacity(0.72))

            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
    }

    private func elementChip(_ element: GameElement) -> some View {
        Circle()
            .fill(element.color)
            .frame(width: 18, height: 18)
            .overlay {
                Text(String(element.displayName.prefix(1)))
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.black.opacity(0.74))
            }
    }

    private func cardProgress(for card: AbilityCardDefinition)
        -> (level: Int, stars: Int)
    {
        let ownedCount = max(
            1,
            ownedCards.first { $0.cardID == card.id }?.count ?? 1
        )
        let level = min(
            card.resolvedMaxLevel,
            1 + (ownedCount - 1) / card.resolvedDuplicatesPerLevel
        )
        let stars = min(
            card.resolvedMaxStars,
            1 + (level - 1) / card.resolvedLevelsPerStar
        )
        return (level: level, stars: stars)
    }
}
