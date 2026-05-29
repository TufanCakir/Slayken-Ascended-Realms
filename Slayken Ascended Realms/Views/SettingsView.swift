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
    @EnvironmentObject var remoteContent: RemoteContentManager

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
    @Query private var dailyLoginProgressRecords: [PlayerDailyLoginProgress]
    @Query private var claimedGifts: [PlayerClaimedGift]
    @Query private var shopOfferProgressRecords: [ShopOfferProgress]
    @Query private var ownedSkins: [OwnedCharacterSkin]
    @Query private var processedTransactions: [ProcessedStoreTransaction]
    @Query private var questClaims: [PlayerQuestClaim]
    @Query private var questCounters: [PlayerQuestCounter]
    @Query private var dailyBattleRewardCaps: [PlayerDailyBattleRewardCap]
    @Query private var skillNodeProgressRecords: [PlayerSkillNodeProgress]

    let onClose: () -> Void
    let onReset: () -> Void
    let onOpenTutorialArchive: () -> Void

    @State private var showResetConfirm = false
    @State private var fullPreloadMessage: String?

    var body: some View {

        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    audioPanel
                    contentDownloadPanel
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

    var contentDownloadPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Live Inhalte", systemImage: "arrow.down.circle.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(
                "Laedt alle Remote-Bilder, Musik, Modelle und Daten vor. Das ist optional; fehlende Inhalte werden sonst beim Spielen automatisch geladen."
            )
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            if remoteContent.isRefreshing {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: remoteContent.refreshProgress)
                        .tint(.cyan)
                    Text(remoteContent.statusText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(2)
                }
            } else if let fullPreloadMessage {
                Text(fullPreloadMessage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                startFullPreload()
            } label: {
                Text(remoteContent.isRefreshing ? "LÄDT..." : "ALLES HERUNTERLADEN")
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
            .disabled(remoteContent.isRefreshing)
            .opacity(remoteContent.isRefreshing ? 0.65 : 1)
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
        for progress in skillNodeProgressRecords {
            modelContext.delete(progress)
        }
        for progress in dailyLoginProgressRecords {
            modelContext.delete(progress)
        }
        for gift in claimedGifts {
            modelContext.delete(gift)
        }
        for progress in shopOfferProgressRecords {
            modelContext.delete(progress)
        }
        for skin in ownedSkins {
            modelContext.delete(skin)
        }
        for transaction in processedTransactions {
            modelContext.delete(transaction)
        }
        for claim in questClaims {
            modelContext.delete(claim)
        }
        for counter in questCounters {
            modelContext.delete(counter)
        }
        for cap in dailyBattleRewardCaps {
            modelContext.delete(cap)
        }

        try? modelContext.save()
        resetPersistedDefaults()
        theme.loadSelected()
        musicManager.resetSettings()
        gameState.resetGameData()
        onReset()
    }

    func startFullPreload() {
        fullPreloadMessage = nil
        Task {
            let didSucceed = await remoteContent.refreshContentIfNeeded(
                mode: .fullPreload
            )

            await MainActor.run {
                if didSucceed {
                    gameState.reloadContent()
                    theme.loadThemes()
                    theme.loadSelected()
                    musicManager.reloadTracks()
                    musicManager.startPlaybackIfNeeded()
                    fullPreloadMessage = "Alle verfuegbaren Inhalte wurden vorbereitet."
                } else {
                    fullPreloadMessage =
                        remoteContent.lastErrorMessage
                        ?? "Download fehlgeschlagen. Bitte Verbindung pruefen."
                }
            }
        }
    }

    private func resetPersistedDefaults() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
    }
}
