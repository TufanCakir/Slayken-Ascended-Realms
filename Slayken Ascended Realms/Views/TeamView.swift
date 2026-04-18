//
//  TeamView.swift
//  Slayken Ascended Realms
//

import SwiftData
import SwiftUI

struct TeamView: View {
    let characters: [SummonCharacter]

    @EnvironmentObject private var gameState: GameState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OwnedSummonCharacter.acquiredAt) private var ownedRecords:
        [OwnedSummonCharacter]
    @Query(sort: \TeamMemberRecord.slotIndex) private var teamRecords:
        [TeamMemberRecord]

    @State private var selectedCharacterID: String?

    private var ownedCharacters: [SummonCharacter] {
        let ownedIDs = Set(ownedRecords.map(\.characterID))
        return characters.filter { ownedIDs.contains($0.id) }
    }

    private var selectedCharacter: SummonCharacter? {
        ownedCharacters.first { $0.id == selectedCharacterID }
            ?? ownedCharacters.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Team")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                Text("Slots \(teamRecords.count)/4")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.76))
            }

            if ownedCharacters.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ownedCharacters) { character in
                            teamCharacterButton(character)
                        }
                    }
                }

                if let selectedCharacter {
                    selectedCharacterPanel(selectedCharacter)
                }
            }
        }
        .padding(14)
        .background(.black.opacity(0.28))
        .background(.ultraThinMaterial.opacity(0.45))
        .onAppear {
            selectedCharacterID =
                selectedCharacterID ?? teamRecords.first?.characterID
                ?? ownedCharacters.first?.id
        }
        .onChange(of: ownedRecords.map(\.characterID)) { _, _ in
            selectedCharacterID =
                selectedCharacterID ?? ownedCharacters.first?.id
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                "Keine Summon-Charaktere",
                systemImage: "person.crop.circle.badge.questionmark"
            )
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            Text(
                "Benutze den Summon-Tab, um Charaktere freizuschalten und ins Team zu setzen."
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            Color.black.opacity(0.38),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func teamCharacterButton(_ character: SummonCharacter) -> some View
    {
        let isSelected = selectedCharacter?.id == character.id
        let isInTeam = teamRecords.contains { $0.characterID == character.id }

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCharacterID = character.id
            }
        } label: {
            ZStack(alignment: .bottomLeading) {

                // 🔹 Image Full Card
                summonImage(character.summonImage)
                    .frame(width: 120, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // 🔹 Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // 🔹 Info Overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)

                    HStack(spacing: 3) {
                        ForEach(0..<character.rarity, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .padding(6)
            }
            .frame(width: 120, height: 150)
            .overlay(alignment: .topTrailing) {
                if isInTeam {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.yellow : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .scaleEffect(isSelected ? 1.05 : 1)
            .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func selectedCharacterPanel(_ character: SummonCharacter)
        -> some View
    {
        let ownedRecord = ownedRecords.first { $0.characterID == character.id }
        let selectedSkinID =
            ownedRecord?.selectedSkinID ?? character.skins.first?.id

        return VStack(spacing: 12) {

            // 🔹 BIG IMAGE
            summonImage(
                character.skins.first { $0.id == selectedSkinID }?.summonImage
                    ?? character.summonImage
            )
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 🔹 Name + Stats
            VStack(spacing: 6) {
                Text(character.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 20) {
                    statView("HP", value: character.hp, icon: "heart.fill")
                    statView("ATK", value: character.attack, icon: "bolt.fill")
                }
            }

            // 🔹 Team Button
            Button {
                PlayerInventoryStore.setTeam(
                    characterID: character.id,
                    in: modelContext
                )
                gameState.saveSummonedCharacter(
                    character,
                    selectedSkinID: selectedSkinID
                )
            } label: {
                Text("Add to Team")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green, in: Capsule())
            }

            // 🔹 Skins
            if !character.skins.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(character.skins) { skin in
                            Button {
                                ownedRecord?.selectedSkinID = skin.id
                                try? modelContext.save()
                            } label: {
                                Text(skin.name)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedSkinID == skin.id
                                            ? Color.blue
                                            : Color.black.opacity(0.4),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            Color.black.opacity(0.5),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }

    private func statView(_ title: String, value: Double, icon: String)
        -> some View
    {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text("\(Int(value))")
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func summonImage(_ imageName: String) -> some View {
        if UIImage(named: imageName) == nil {
            Image(systemName: "person.crop.square.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.78))
                .padding(26)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.34))
        } else {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.34))
        }
    }
}
