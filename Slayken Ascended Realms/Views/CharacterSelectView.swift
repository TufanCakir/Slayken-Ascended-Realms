//
//  CharacterSelectView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct CharacterSelectView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case team = "Team"
        case legacy = "Direct"

        var id: String { rawValue }
    }

    var onClose: (() -> Void)? = nil

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    @State private var mode: Mode = .team
    @State private var selectedModel = ""
    @State private var didSave = false

    private var selectedCharacter: CharacterStats? {
        gameState.availableCharacters.first { $0.model == selectedModel }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Picker("Character Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 14) {
                    switch mode {
                    case .team:
                        TeamView(characters: gameState.summonCharacters)
                    case .legacy:
                        directCharacterSelection
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 28)
            }
        }

        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.48), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close Character")
                } else {
                    Color.clear.frame(width: 38, height: 38)
                }

                Spacer()

                Text("Team")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Color.clear.frame(width: 38, height: 38)
            }
            .padding(.horizontal, 16)

            Rectangle()
                .fill(.white.opacity(0.26))
                .frame(height: 1)
                .padding(.horizontal, 62)
        }
        .padding(.top, 58)
        .padding(.bottom, 12)
    }

    private var background: some View {
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

    private var directCharacterSelection: some View {
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
                    Label(
                        didSave ? "Gespeichert" : "Speichern",
                        systemImage: didSave
                            ? "checkmark.circle.fill" : "square.and.arrow.down"
                    )
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
        .background(.black.opacity(0.28))
        .background(.ultraThinMaterial.opacity(0.45))
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
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    HStack(spacing: 10) {
                        statLabel(icon: "heart.fill", value: Int(character.hp))
                        statLabel(
                            icon: "bolt.fill",
                            value: Int(character.attack)
                        )
                    }
                }
            }
            .padding(10)
            .frame(width: 200)
            .background(Color.black.opacity(isSelected ? 0.72 : 0.46))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? accent : .white.opacity(0.22),
                        lineWidth: isSelected ? 3 : 1
                    )
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
                .scaledToFit()
        }
    }
}

#Preview {
    CharacterSelectView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
