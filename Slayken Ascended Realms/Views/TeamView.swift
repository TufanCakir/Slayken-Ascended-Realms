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
    @Query(sort: \OwnedSummonCharacter.acquiredAt) private var ownedRecords: [OwnedSummonCharacter]
    @Query(sort: \TeamMemberRecord.slotIndex) private var teamRecords: [TeamMemberRecord]

    @State private var selectedCharacterID: String?

    private var ownedCharacters: [SummonCharacter] {
        let ownedIDs = Set(ownedRecords.map(\.characterID))
        return characters.filter { ownedIDs.contains($0.id) }
    }

    private var selectedCharacter: SummonCharacter? {
        ownedCharacters.first { $0.id == selectedCharacterID } ?? ownedCharacters.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Team")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                Spacer()
                Text("Slots 1/4")
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
            selectedCharacterID = selectedCharacterID ?? teamRecords.first?.characterID ?? ownedCharacters.first?.id
        }
        .onChange(of: ownedRecords.map(\.characterID)) { _, _ in
            selectedCharacterID = selectedCharacterID ?? ownedCharacters.first?.id
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keine Summon-Charaktere", systemImage: "person.crop.circle.badge.questionmark")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
            Text("Benutze den Summon-Tab, um Charaktere freizuschalten und ins Team zu setzen.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func teamCharacterButton(_ character: SummonCharacter) -> some View {
        let isSelected = selectedCharacter?.id == character.id
        let isInTeam = teamRecords.contains { $0.characterID == character.id }

        return Button {
            selectedCharacterID = character.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                summonImage(character.summonImage)
                    .frame(width: 112, height: 126)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(character.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(0..<character.rarity, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .padding(8)
            .frame(width: 128)
            .background(Color.black.opacity(isSelected ? 0.74 : 0.44))
            .overlay(alignment: .topTrailing) {
                if isInTeam {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.green)
                        .padding(6)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.72) : Color.white.opacity(0.16), lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func selectedCharacterPanel(_ character: SummonCharacter) -> some View {
        let ownedRecord = ownedRecords.first { $0.characterID == character.id }
        let selectedSkinID = ownedRecord?.selectedSkinID ?? character.skins.first?.id

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                summonImage(character.skins.first { $0.id == selectedSkinID }?.summonImage ?? character.summonImage)
                    .frame(width: 74, height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(character.name)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        Label("\(Int(character.hp))", systemImage: "heart.fill")
                        Label("\(Int(character.attack))", systemImage: "bolt.fill")
                    }
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.84))
                }

                Spacer()

                Button {
                    PlayerInventoryStore.setTeam(characterID: character.id, in: modelContext)
                    gameState.saveSummonedCharacter(character, selectedSkinID: selectedSkinID)
                } label: {
                    Label("Team", systemImage: "person.3.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.green.opacity(0.72), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if !character.skins.isEmpty {
                Text("Skins")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(character.skins) { skin in
                            Button {
                                ownedRecord?.selectedSkinID = skin.id
                                try? modelContext.save()
                                gameState.saveSummonedCharacter(character, selectedSkinID: skin.id)
                            } label: {
                                Text(skin.name)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        Color.black.opacity(selectedSkinID == skin.id ? 0.72 : 0.38),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.34))
        }
    }
}
