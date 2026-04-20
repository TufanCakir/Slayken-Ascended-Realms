//
//  TeamView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

struct TeamView: View {
    private enum ActiveSheet: Identifiable {
        case character
        case card(slot: Int)
        case cards

        var id: String {
            switch self {
            case .character: return "character"
            case .card(let slot): return "card_\(slot)"
            case .cards: return "cards"
            }
        }
    }

    let characters: [SummonCharacter]

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var gameState: GameState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OwnedSummonCharacter.acquiredAt) private var ownedRecords:
        [OwnedSummonCharacter]
    @Query(sort: \TeamMemberRecord.slotIndex) private var teamRecords:
        [TeamMemberRecord]
    @Query(sort: \PlayerDeckCardSlot.slotIndex) private var deckSlots:
        [PlayerDeckCardSlot]
    @Query(sort: \OwnedAbilityCard.acquiredAt) private var ownedCards:
        [OwnedAbilityCard]

    @State private var activeSheet: ActiveSheet?

    private let deckSlotCount = 8

    private var selectedCharacter: SummonCharacter? {
        guard
            let teamCharacterID = teamRecords.first(where: { $0.slotIndex == 0 }
            )?.characterID
        else { return nil }
        return characters.first { $0.id == teamCharacterID }
    }

    private var selectedOwnedRecord: OwnedSummonCharacter? {
        guard let selectedCharacter else { return nil }
        return ownedRecords.first { $0.characterID == selectedCharacter.id }
    }

    private var selectedSkin: CharacterSkin? {
        guard let selectedCharacter else { return nil }
        let selectedSkinID = selectedOwnedRecord?.selectedSkinID
        return selectedCharacter.skins.first { $0.id == selectedSkinID }
            ?? selectedCharacter.skins.first
    }

    private var deckMultiplier: Double {
        deckSlots.reduce(1.0) { total, slot in
            let card = gameState.abilityCards.first { $0.id == slot.cardID }
            return total * (card?.damageMultiplier ?? 1.0)
        }
    }

    var body: some View {

        VStack(spacing: 14) {
            Text("Decks")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

            deckPanel

            Button {
                activeSheet = .cards
            } label: {
                Label("Meine Karten", systemImage: "rectangle.stack.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.black.opacity(0.44), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .character:
                TeamCharacterPickerView(characters: characters) {
                    character,
                    skinID in
                    PlayerInventoryStore.setTeam(
                        characterID: character.id,
                        in: modelContext
                    )
                    if let record = ownedRecords.first(where: {
                        $0.characterID == character.id
                    }) {
                        record.selectedSkinID = skinID
                        try? modelContext.save()
                    }
                    gameState.saveSummonedCharacter(
                        character,
                        selectedSkinID: skinID
                    )
                    activeSheet = nil
                } onClose: {
                    activeSheet = nil
                }
                .environmentObject(gameState)

            case .card(let slot):
                TeamCardPickerView(slotIndex: slot) { card in
                    PlayerInventoryStore.setDeckCard(
                        cardID: card.id,
                        slotIndex: slot,
                        in: modelContext
                    )
                    activeSheet = nil
                } onClose: {
                    activeSheet = nil
                }
                .environmentObject(gameState)

            case .cards:
                CardCollectionView(onClose: {
                    activeSheet = nil
                })
                .environmentObject(gameState)
            }
        }
    }

    private var deckPanel: some View {
        VStack(spacing: 10) {
            characterSlot

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 8),
                    count: 4
                ),
                spacing: 8
            ) {
                ForEach(0..<deckSlotCount, id: \.self) { index in
                    cardSlot(index)
                }
            }

            HStack(spacing: 12) {
                deckMetric(
                    "Cards",
                    value: "\(deckSlots.count)/\(deckSlotCount)"
                )
                deckMetric(
                    "Damage",
                    value: "x\(String(format: "%.2f", deckMultiplier))"
                )
                deckMetric(
                    "Owned",
                    value: "\(ownedCards.reduce(0) { $0 + $1.count })"
                )
            }
        }
        .padding()
    }

    private var characterSlot: some View {
        Button {
            activeSheet = .character
        } label: {
            HStack(spacing: 10) {
                slotImage(
                    selectedSkin?.summonImage ?? selectedCharacter?.summonImage,
                    fallback: "person.crop.square.fill"
                )
                .frame(width: 66, height: 66)
                .clipShape(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5).stroke(
                        .white.opacity(0.62),
                        lineWidth: 1
                    )
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedCharacter?.name ?? "Character Slot")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(
                        selectedCharacter == nil
                            ? "Tippen zum Auswaehlen"
                            : "Skin: \(selectedSkin?.name ?? "Original")"
                    )
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(9)
            .background(
                Color.black.opacity(0.32),
                in: RoundedRectangle(cornerRadius: 5, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func cardSlot(_ index: Int) -> some View {
        let slot = deckSlots.first { $0.slotIndex == index }
        let card = slot.flatMap { slot in
            gameState.abilityCards.first { $0.id == slot.cardID }
        }

        return Button {
            activeSheet = .card(slot: index)
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let card {
                    slotImage(card.image, fallback: "sparkles")
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.82)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    Text(card.name)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(4)
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black.opacity(0.52))
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .black))
                        Text("Skill")
                            .font(.system(size: 8, weight: .black))
                    }
                    .foregroundStyle(.white.opacity(0.68))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .aspectRatio(0.72, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(
                    .white.opacity(0.52),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func deckMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.70))
            Text(value)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func slotImage(_ imageName: String?, fallback: String) -> some View
    {
        if let imageName, UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.black.opacity(0.76), .cyan.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: fallback)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }
}
