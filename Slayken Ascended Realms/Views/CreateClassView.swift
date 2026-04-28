//
//  CreateClassView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

struct CreateClassView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager

    let onComplete: (CharacterStats) -> Void

    @State private var selectedClassID = ""
    @State private var selectedVariantID = ""
    @State private var characterName = ""
    @State private var ascendedLevel = 1

    private let classDefinitions = loadCharacterClassDefinitions()

    var body: some View {
        ZStack {

            if let selectedClass, let selectedVariant {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        previewCard(
                            for: selectedClass,
                            variant: selectedVariant
                        )
                        classPicker
                        variantPicker(for: selectedClass)
                        nameCard(for: selectedClass)
                        confirmButton(for: selectedVariant)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
                .safeAreaPadding(.top, 12)
            } else {
                unavailableState
                    .padding(.horizontal, 24)
            }
        }
        .onAppear {
            guard !classDefinitions.isEmpty else { return }

            refreshAscendedLevel()
            if selectedClassID.isEmpty {
                selectedClassID = classDefinitions[0].id
            }
            syncSelectionWithActiveClass()
        }
        .onChange(of: selectedClassID) {
            syncSelectionWithActiveClass()
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

    private var selectedClass: CharacterClassDefinition? {
        classDefinitions.first { $0.id == selectedClassID }
            ?? classDefinitions.first
    }

    private var selectedVariant: CharacterClassVariant? {
        selectedClass?.variants.first { $0.id == selectedVariantID }
            ?? selectedClass?.defaultVariant
    }

    private var previewCharacter: CharacterStats? {
        guard let selectedClass, let selectedVariant else { return nil }
        return selectedVariant.makeCharacter(
            named: resolvedCharacterName(for: selectedClass)
        )
    }

    private var standardClasses: [CharacterClassDefinition] {
        classDefinitions.filter { !$0.isHeroClass }
    }

    private var heroClasses: [CharacterClassDefinition] {
        classDefinitions.filter(\.isHeroClass)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create Class")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text(
                "Waehle deine Klasse, gib deinem Helden einen eigenen Namen und schalte spaeter Heldenklassen ueber dein Ascended Level frei."
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.82))
            .multilineTextAlignment(.center)

            Text("Ascended Level \(ascendedLevel)")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.cyan.opacity(0.92))
        }
        .padding(.top, 20)
    }

    private func previewCard(
        for selectedClass: CharacterClassDefinition,
        variant: CharacterClassVariant
    ) -> some View {
        let character = variant.makeCharacter(
            named: resolvedCharacterName(for: selectedClass)
        )

        return VStack(spacing: 12) {
            GameSceneView(
                player: character,
                joystickVector: .zero,
                autoMoveTarget: nil,
                groundTexture: gameState.selectedMap.mapImage,
                skyboxTexture: theme.selectedTheme?.background
                    ?? gameState.selectedBackground.image
            )
            .id(character.model)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }

            HStack(spacing: 12) {
                statChip(title: "Klasse", value: selectedClass.title)
                statChip(title: "HP", value: "\(Int(character.hp))")
                statChip(title: "ATK", value: "\(Int(character.attack))")
            }
        }
    }

    private var classPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Klassen")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            classSection(
                title: "Standardklassen",
                subtitle: "Sofort verfuegbar",
                classes: standardClasses
            )

            if !heroClasses.isEmpty {
                classSection(
                    title: "Heldenklassen",
                    subtitle: "Werden ueber dein Ascended Level freigeschaltet",
                    classes: heroClasses
                )
            }
        }
    }

    private func variantPicker(for selectedClass: CharacterClassDefinition)
        -> some View
    {
        VStack(alignment: .leading, spacing: 10) {
            Text("Variante")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                ForEach(selectedClass.variants) { variant in
                    Button {
                        selectedVariantID = variant.id
                    } label: {
                        Text(variant.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedVariantID == variant.id
                                    ? Color.white.opacity(0.2)
                                    : Color.black.opacity(0.28)
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                                .stroke(
                                    .white.opacity(
                                        selectedVariantID == variant.id
                                            ? 0.22 : 0.08
                                    ),
                                    lineWidth: 1
                                )
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func nameCard(for selectedClass: CharacterClassDefinition)
        -> some View
    {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            TextField(selectedClass.defaultName, text: $characterName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.34))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(.white)
        }
    }

    private func confirmButton(for selectedVariant: CharacterClassVariant)
        -> some View
    {
        Button {
            if let previewCharacter {
                onComplete(previewCharacter)
            } else if let selectedClass {
                onComplete(
                    selectedVariant.makeCharacter(
                        named: resolvedCharacterName(for: selectedClass)
                    )
                )
            }
        } label: {
            Text(
                isSelectedClassLocked
                    ? "Ascended Level zu niedrig" : "Held erstellen"
            )
            .font(.system(size: 17, weight: .black))
            .foregroundStyle(isSelectedClassLocked ? .white : .black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelectedClassLocked
                    ? Color.gray.opacity(0.45)
                    : Color(red: 0.93, green: 0.83, blue: 0.34)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
        .disabled(isSelectedClassLocked)
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Text("Keine Klassen gefunden")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
            Text(
                "Lege Einträge in `character_classes.json` an, damit die Klassenerstellung Inhalte laden kann."
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.74))
            .multilineTextAlignment(.center)
        }
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func syncSelectionWithActiveClass() {
        guard let selectedClass else { return }

        if isClassLocked(selectedClass),
            let fallback = classDefinitions.first(where: { !isClassLocked($0) })
        {
            if selectedClass.id != fallback.id {
                selectedClassID = fallback.id
            }
            return
        }

        if selectedVariantID.isEmpty
            || !selectedClass.variants.contains(where: {
                $0.id == selectedVariantID
            })
        {
            selectedVariantID = selectedClass.defaultVariant?.id ?? ""
        }

        if characterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            characterName = selectedClass.defaultName
        }
    }

    private func resolvedCharacterName(
        for selectedClass: CharacterClassDefinition
    ) -> String {
        let trimmedName = characterName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedName.isEmpty ? selectedClass.defaultName : trimmedName
    }

    private func refreshAscendedLevel() {
        ascendedLevel =
            PlayerInventoryStore.accountProgress(in: modelContext).level
    }

    private var isSelectedClassLocked: Bool {
        guard let selectedClass else { return true }
        return isClassLocked(selectedClass)
    }

    private func isClassLocked(_ definition: CharacterClassDefinition) -> Bool {
        ascendedLevel < definition.requiredAscendedLevel
    }

    private func classSection(
        title: String,
        subtitle: String,
        classes: [CharacterClassDefinition]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            ForEach(classes) { definition in
                classCard(definition)
            }
        }
    }

    private func classCard(_ definition: CharacterClassDefinition) -> some View
    {
        let isLocked = isClassLocked(definition)
        let isSelected = selectedClassID == definition.id

        return Button {
            guard !isLocked else { return }
            selectedClassID = definition.id
        } label: {
            HStack(alignment: .top, spacing: 14) {
                classPreviewImage(for: definition)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(definition.title)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)

                        if definition.isHeroClass {
                            Text("HERO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.yellow, in: Capsule())
                        }
                    }

                    Text(definition.summary)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    if isLocked {
                        Text(
                            "Freischaltung ab Ascended Level \(definition.requiredAscendedLevel)"
                        )
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.orange.opacity(0.95))
                    }
                }

                Spacer()

                Image(
                    systemName: isLocked
                        ? "lock.fill"
                        : isSelected ? "checkmark.circle.fill" : "circle"
                )
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(
                    isLocked
                        ? .orange : isSelected ? .yellow : .white.opacity(0.45)
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.black.opacity(
                    isLocked ? 0.22 : isSelected ? 0.54 : 0.34
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isLocked
                            ? .orange.opacity(0.16)
                            : .white.opacity(isSelected ? 0.2 : 0.08),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func classPreviewImage(for definition: CharacterClassDefinition)
        -> some View
    {
        let imageName = definition.defaultVariant?.image ?? ""
        let hasImage = !imageName.isEmpty && UIImage(named: imageName) != nil

        return ZStack(alignment: .bottomLeading) {
            if hasImage {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.black.opacity(0.32),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "person.crop.rectangle.stack.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))
            }

            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.72),
                ],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(definition.defaultVariant?.title ?? "Class")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.94))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(width: 108, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

#Preview {
    CreateClassView(onComplete: { _ in })
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
