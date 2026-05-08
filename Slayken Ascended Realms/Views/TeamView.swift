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
        case skillTree

        var id: String {
            switch self {
            case .character: return "character"
            case .card(let slot): return "card_\(slot)"
            case .skillTree: return "skill_tree"
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
    @Query(sort: \PlayerCharacterProgress.characterID) private
        var characterProgress: [PlayerCharacterProgress]

    @State private var activeSheet: ActiveSheet?

    private var deckSlotCount: Int {
        loadDeckConfiguration().resolvedSlotCount
    }

    private var selectedTeamCharacterID: String? {
        teamRecords.first(where: { $0.slotIndex == 0 })?.characterID
    }

    private var selectedCharacter: SummonCharacter? {
        guard let teamCharacterID = selectedTeamCharacterID else { return nil }
        return characters.first { $0.id == teamCharacterID }
    }

    private var selectedOwnedRecord: OwnedSummonCharacter? {
        guard let selectedCharacter else { return nil }
        return ownedRecords.first { $0.characterID == selectedCharacter.id }
    }

    private var selectedCharacterStats: CharacterStats? {
        guard let teamCharacterID = selectedTeamCharacterID else {
            return gameState.player.model.isEmpty ? nil : gameState.player
        }

        if let selectedCharacter {
            return selectedCharacter.stats(
                selectedSkinID: selectedOwnedRecord?.selectedSkinID
            )
        }

        if let availableCharacter = gameState.availableCharacters.first(where: {
            $0.model == teamCharacterID
        }) {
            return availableCharacter
        }

        return teamCharacterID == gameState.player.model
            ? gameState.player : nil
    }

    private var selectedCharacterLevel: Int {
        guard let selectedCharacterStats else { return 1 }
        return characterProgress.first(where: {
            $0.characterID == selectedCharacterStats.model
        })?.level ?? 1
    }

    private var selectedSkin: CharacterSkin? {
        guard let selectedCharacter else { return nil }
        let selectedSkinID = selectedOwnedRecord?.selectedSkinID
        return selectedCharacter.skins.first { $0.id == selectedSkinID }
    }

    private var deckMultiplier: Double {
        deckSlots.reduce(1.0) { total, slot in
            let card = gameState.abilityCards.first { $0.id == slot.cardID }
            return total * (card?.damageMultiplier ?? 1.0)
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            deckPanel
            heroStage
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
                        $0.characterID == character.model
                    }) {
                        record.selectedSkinID = skinID
                        try? modelContext.save()
                    }
                    if let summonCharacter = characters.first(where: {
                        $0.id == character.model
                    }) {
                        gameState.saveSummonedCharacter(
                            summonCharacter,
                            selectedSkinID: skinID
                        )
                    } else {
                        gameState.saveCharacter(character)
                    }
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

            case .skillTree:
                SkillTreeView(
                    character: selectedCharacterStats ?? gameState.player,
                    onClose: {
                        activeSheet = nil
                    }
                )
                .environmentObject(gameState)
                .environmentObject(themeManager)
            }
        }
    }

    private var deckPanel: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCharacterStats?.name ?? "Class Slot")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white)
                    Text("Lv. \(selectedCharacterLevel)")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(
                            Color(red: 0.75, green: 0.96, blue: 1.0)
                        )
                }

                Spacer()

                VStack(spacing: 8) {
                    panelButton(title: "Full Edit") {
                        activeSheet = .character
                    }
                    panelButton(title: "Skill Panel") {
                        activeSheet = .skillTree
                    }
                }
            }

            characterSlot

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<deckSlotCount, id: \.self) { index in
                        cardSlot(index)
                            .frame(width: 82)
                    }
                }
            }

            HStack(spacing: 12) {
                deckMetric(
                    "Abilities",
                    value: "\(deckSlots.count)/\(deckSlotCount)"
                )
                deckMetric(
                    "Created",
                    value: "+\(max(0, Int((deckMultiplier - 1.0) * 100)))%"
                )
                deckMetric(
                    "Owned",
                    value: "\(ownedCards.reduce(0) { $0 + $1.count })"
                )
            }
        }
        .padding(14)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var characterSlot: some View {
        Button {
            activeSheet = .character
        } label: {
            HStack(spacing: 10) {
                slotImage(
                    selectedSkin?.summonImage ?? selectedCharacterStats?.image,
                    fallback: "person.crop.square.fill"
                )
                .frame(width: 66, height: 66)
                .clipShape(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
                .background(
                    Color.black.opacity(0.34),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedCharacterStats?.name ?? "Character Slot")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(
                        selectedCharacter == nil
                            ? "Aktive Startklasse"
                            : "Skin: \(selectedSkin?.name ?? "Standard")"
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
                Color.black.opacity(0.26),
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
            .aspectRatio(0.74, contentMode: .fit)
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

    private var heroStage: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.black.opacity(0.28),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(alignment: .bottom, spacing: 16) {
                statPanel

                Spacer(minLength: 0)
            }
            .padding(16)

            if let selectedCharacterStats {
                GameSceneView(
                    player: selectedCharacterStats,
                    joystickVector: .zero,
                    autoMoveTarget: nil,
                    groundTexture: gameState.selectedMap.mapImage,
                    skyboxTexture: themeManager.selectedTheme?.background
                        ?? gameState.selectedBackground.image
                )
                .id(selectedCharacterStats.model)
                .frame(height: 360)
                .allowsHitTesting(false)
            }
        }
        .frame(height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var statPanel: some View {
        let character = selectedCharacterStats

        return VStack(alignment: .leading, spacing: 8) {
            Text("Job")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
            Text(character?.name ?? "Keine Klasse")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            if let element = character?.element {
                Text("Element \(GameElement(element).displayName)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(GameElement(element).color)
            }

            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(width: 112, height: 1)
                .padding(.vertical, 4)

            statRow(title: "HP", value: Int(character?.hp ?? 0))
            statRow(title: "Attack", value: Int(character?.attack ?? 0))
            statRow(title: "Skills", value: min(deckSlots.count, deckSlotCount))
            statRow(title: "Deck", value: deckSlotCount)
        }
        .padding(12)
        .background(
            Color.black.opacity(0.32),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
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

    private func statRow(title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.76))
            Spacer()
            Text("\(value)")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 112)
    }

    private func panelButton(title: String, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Color.black.opacity(0.34),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func slotImage(_ imageName: String?, fallback: String) -> some View
    {
        if let imageName {
            RemoteAssetImage(imageName, contentMode: .fit) {
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
