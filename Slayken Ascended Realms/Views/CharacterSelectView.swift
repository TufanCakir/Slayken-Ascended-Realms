//
//  CharacterSelectView.swift
//  Slayken Ascended Realms
//

import SwiftUI

struct CharacterSelectView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    @State private var selectedModel = ""
    @State private var didSave = false

    private var selectedCharacter: CharacterStats? {
        gameState.availableCharacters.first { $0.model == selectedModel }
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Character")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    guard let selectedCharacter else { return }
                    gameState.saveCharacter(selectedCharacter)
                    didSave = true
                } label: {
                    Label(didSave ? "Gespeichert" : "Speichern", systemImage: didSave ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(saveButtonColor, in: Capsule())
                }
                .disabled(selectedCharacter == nil)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(gameState.availableCharacters) { character in
                        characterButton(character)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.48))
        .background(.ultraThinMaterial)
        .onAppear {
            if selectedModel.isEmpty {
                selectedModel = gameState.player.model
            }
        }
        .onChange(of: selectedModel) {
            didSave = selectedModel == gameState.player.model
        }
        .onChange(of: gameState.player.model) {
            didSave = selectedModel == gameState.player.model
        }
    }

    private var saveButtonColor: Color {
        if didSave {
            return theme.selectedTheme?.secondary.color ?? .green
        }

        return theme.selectedTheme?.primary.color ?? .blue
    }

    private func characterButton(_ character: CharacterStats) -> some View {
        let isSelected = selectedModel == character.model
        let accent = theme.selectedTheme?.primary.color ?? .blue

        return Button {
            selectedModel = character.model
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                characterIcon(character)
                    .frame(width: 180, height: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    HStack(spacing: 10) {
                        statLabel(icon: "heart.fill", value: Int(character.hp))
                        statLabel(icon: "bolt.fill", value: Int(character.attack))
                    }
                }
            }
            .padding(10)
            .frame(width: 200)
            .background(Color.black.opacity(isSelected ? 0.72 : 0.46))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? accent : .white.opacity(0.22), lineWidth: isSelected ? 3 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func statLabel(icon: String, value: Int) -> some View {
        Label("\(value)", systemImage: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))
    }

    @ViewBuilder
    private func characterIcon(_ character: CharacterStats) -> some View {
        if character.image.isEmpty {
            Image(systemName: "person.crop.square.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white.opacity(0.8))
                .padding(42)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.35))
        } else {
            Image(character.image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.35))
        }
    }
}


#Preview {
    CharacterSelectView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
