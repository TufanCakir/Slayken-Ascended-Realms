//
//  TeamCharacterPickerView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct TeamCharacterPickerView: View {
    private struct PickerCharacterEntry: Identifiable {
        let id: String
        let stats: CharacterStats
        let summonCharacter: SummonCharacter?
    }

    let characters: [SummonCharacter]
    let onSelect: (CharacterStats, String?, String?) -> Void
    let onClose: () -> Void

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    @Query(sort: \OwnedSummonCharacter.acquiredAt) private var ownedRecords:
        [OwnedSummonCharacter]
    @Query(sort: \OwnedCharacterSkin.acquiredAt) private var ownedSkins:
        [OwnedCharacterSkin]
    @State private var selectedCharacterID: String?
    @State private var selectedSkinID: String?

    private var ownedCharacters: [SummonCharacter] {
        let ownedIDs = Set(ownedRecords.map(\.characterID))
        return characters.filter { ownedIDs.contains($0.id) }
    }

    private var pickerEntries: [PickerCharacterEntry] {
        ownedCharacters.map {
            PickerCharacterEntry(
                id: $0.id,
                stats: $0.stats(),
                summonCharacter: $0
            )
        }
    }

    private var selectedEntry: PickerCharacterEntry? {
        pickerEntries.first { $0.id == selectedCharacterID }
            ?? pickerEntries.first
    }

    private var selectedCharacter: SummonCharacter? {
        selectedEntry?.summonCharacter
    }

    private var unlockedSkinsForSelectedCharacter: [CharacterSkin] {
        guard let selectedCharacter else { return [] }
        let ownedSkinIDs = Set(
            ownedSkins
                .filter { $0.characterID == selectedCharacter.id }
                .map(\.skinID)
        )
        return selectedCharacter.skins.filter { ownedSkinIDs.contains($0.id) }
    }

    var body: some View {

        VStack(spacing: 12) {
            header(title: "Character Slot")

            if pickerEntries.isEmpty {
                emptyState(
                    text:
                        "Keine Charaktere verfuegbar. Erstelle eine Klasse oder ziehe Characters im Summon.",
                    icon: "person.crop.square.fill"
                )
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        characterGrid
                        skinPicker
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }

                Button {
                    if let selectedEntry {
                        onSelect(
                            selectedEntry.stats,
                            selectedSkinID,
                            selectedEntry.summonCharacter?.id
                        )
                    }
                } label: {
                    Text("Einsetzen")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.cyan.opacity(0.74), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .onAppear {
            selectedCharacterID =
                selectedCharacterID ?? pickerEntries.first?.id
        }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    RemoteAssetImage(theme.background) {
                        Color.black.opacity(0.35)
                    }
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

    private var characterGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            ForEach(pickerEntries) { entry in
                Button {
                    let previousCharacterID = selectedCharacterID
                    selectedCharacterID = entry.id
                    if previousCharacterID != entry.id {
                        selectedSkinID = nil
                    }
                } label: {
                    VStack(spacing: 7) {
                        image(
                            entry.summonCharacter?.summonImage
                                ?? entry.stats.image,
                            fallback: "person.crop.square.fill"
                        )
                        .frame(height: 138)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 6,
                                style: .continuous
                            )
                        )
                        Text(entry.stats.name)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(7)
                    .background(
                        Color.black.opacity(0.42),
                        in: RoundedRectangle(
                            cornerRadius: 7,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7).stroke(
                            selectedCharacterID == entry.id
                                ? .yellow : .white.opacity(0.22),
                            lineWidth: selectedCharacterID == entry.id
                                ? 2 : 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var skinPicker: some View {
        if let selectedCharacter, !selectedCharacter.skins.isEmpty {
            let unlockedSkins = unlockedSkinsForSelectedCharacter
            VStack(alignment: .leading, spacing: 8) {
                Text("Skins")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedSkinID = nil
                        } label: {
                            Text("Kein Skin")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedSkinID == nil
                                        ? Color.cyan.opacity(0.78)
                                        : Color.black.opacity(0.46),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)

                        ForEach(unlockedSkins) { skin in
                            Button {
                                selectedSkinID = skin.id
                            } label: {
                                Text(skin.name)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedSkinID == skin.id
                                            ? Color.cyan.opacity(0.78)
                                            : Color.black.opacity(0.46),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        if unlockedSkins.isEmpty {
                            Text("Keine Skins freigeschaltet")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white.opacity(0.64))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Color.black.opacity(0.28),
                                    in: Capsule()
                                )
                        }
                    }
                }
            }
            .padding(12)
            .background(
                Color.black.opacity(0.30),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
    }

    private func header(title: String) -> some View {
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
            Text(title)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 58)
    }

    private func emptyState(text: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .black))
            Text(text)
                .font(.system(size: 14, weight: .black))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    @ViewBuilder
    private func image(_ imageName: String?, fallback: String) -> some View {
        if let imageName {
            RemoteAssetImage(imageName, contentMode: .fit) {
                ZStack {
                    Color.black.opacity(0.42)
                    Image(systemName: fallback)
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        } else {
            ZStack {
                Color.black.opacity(0.42)
                Image(systemName: fallback)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
    }
}
