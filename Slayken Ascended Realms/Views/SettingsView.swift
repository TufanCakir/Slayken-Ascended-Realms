//
//  SettingsView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var musicManager: MusicManager

    @Query private var currencyBalances: [PlayerCurrencyBalance]
    @Query private var ownedCharacters: [OwnedSummonCharacter]
    @Query private var teamMembers: [TeamMemberRecord]
    @Query private var battleProgress: [PlayerBattleProgress]
    @Query private var deckSlots: [PlayerDeckCardSlot]
    @Query private var ownedCards: [OwnedAbilityCard]
    @Query private var characterProgress: [PlayerCharacterProgress]
    @Query private var accountProgress: [PlayerAccountProgress]
    @Query private var seenCutscenes: [SeenCutsceneRecord]
    @Query private var summonProgress: [SummonBannerProgress]
    @Query private var battleResourceStates: [PlayerBattleResourceState]

    let onClose: () -> Void
    let onReset: () -> Void
    let onOpenTutorialArchive: () -> Void

    @State private var showResetConfirm = false

    var body: some View {

        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    audioPanel
                    tutorialPanel
                    resetPanel
                    dataPanel
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .confirmationDialog(
            "Spielstand wirklich zuruecksetzen?",
            isPresented: $showResetConfirm
        ) {
            Button("Alles zuruecksetzen", role: .destructive) {
                resetAllGameData()
            }
            Button("Abbrechen", role: .cancel) {}
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

    var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        .white.opacity(0.12),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
            }

            Spacer()

            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(.white.opacity(0.74))
                .frame(width: 38, height: 38)
                .background(
                    .white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .padding()
    }

    var resetPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reset Game", systemImage: "arrow.counterclockwise")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                "Setzt dein komplettes Spiel zurueck. Dieser Vorgang kann nicht rueckgaengig gemacht werden."
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.leading)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showResetConfirm = true
            } label: {
                Text("RESET ALL DATA")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: .red.opacity(0.6), radius: 10)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            .white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12))
        )
    }

    var tutorialPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tutorial", systemImage: "book.closed.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                "Oeffnet das Tutorial Archiv, damit du abgeschlossene Einfuehrungen erneut spielen kannst."
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onOpenTutorialArchive()
            } label: {
                Text("TUTORIAL ARCHIV")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.cyan.opacity(0.95), .blue.opacity(0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            .white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12))
        )
    }

    var audioPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Music", systemImage: "music.note")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Text(musicManager.isEnabled ? "Aktiv" : "Aus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Button {
                    musicManager.toggleEnabled()
                } label: {
                    Text(musicManager.isEnabled ? "MUSIK AUS" : "MUSIK AN")
                        .font(.system(size: 12, weight: .black))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            musicManager.isEnabled
                                ? Color.red.opacity(0.85)
                                : Color.green.opacity(0.85),
                            in: RoundedRectangle(
                                cornerRadius: 10,
                                style: .continuous
                            )
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Lautstaerke")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))

                    Spacer()

                    Text("\(Int(musicManager.volume * 100))%")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                }

                Slider(
                    value: Binding(
                        get: { musicManager.volume },
                        set: { musicManager.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(.cyan)
                .disabled(!musicManager.isEnabled)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            .white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.12))
        )
    }

    var dataPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PLAYER DATA")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white.opacity(0.7))

            statRow("Waehrungen", currencyBalances.count)
            statRow("Charaktere", ownedCharacters.count)
            statRow("Team Slots", teamMembers.count)
            statRow("Battle Fortschritt", battleProgress.count)
            statRow("Deck Karten", deckSlots.count)
            statRow("Karten Besitz", ownedCards.count)
            statRow("Charakter Level", characterProgress.count)
            statRow("Ascended Level", accountProgress.count)
            statRow("Gesehene Cutscenes", seenCutscenes.count)
            statRow("Banner Fortschritt", summonProgress.count)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .white.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.10))
        )
    }

    func statRow(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer()

                Text("\(value)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.cyan.opacity(0.7), .white.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .frame(width: max(18, CGFloat(min(value, 100)) * 2))
                .animation(.easeInOut, value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func resetAllGameData() {
        for balance in currencyBalances {
            modelContext.delete(balance)
        }
        for character in ownedCharacters {
            modelContext.delete(character)
        }
        for member in teamMembers {
            modelContext.delete(member)
        }
        for progress in battleProgress {
            modelContext.delete(progress)
        }
        for slot in deckSlots {
            modelContext.delete(slot)
        }
        for card in ownedCards {
            modelContext.delete(card)
        }
        for progress in characterProgress {
            modelContext.delete(progress)
        }
        for progress in accountProgress {
            modelContext.delete(progress)
        }
        for record in seenCutscenes {
            modelContext.delete(record)
        }
        for progress in summonProgress {
            modelContext.delete(progress)
        }
        for state in battleResourceStates {
            modelContext.delete(state)
        }

        try? modelContext.save()
        gameState.resetGameData()
        onReset()
    }

}

#Preview {
    SettingsView(onClose: {}, onReset: {}, onOpenTutorialArchive: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
        .modelContainer(
            for: [
                PlayerCurrencyBalance.self,
                OwnedSummonCharacter.self,
                TeamMemberRecord.self,
                PlayerBattleProgress.self,
                PlayerDeckCardSlot.self,
                OwnedAbilityCard.self,
                PlayerCharacterProgress.self,
                PlayerAccountProgress.self,
                SeenCutsceneRecord.self,
                SummonBannerProgress.self,
                PlayerBattleResourceState.self,
            ],
            inMemory: true
        )
}
