//
//  CoopRaidFlowView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct CoopRaidFlowView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager

    private enum Step {
        case bossSelection
        case lobby
    }

    @State private var step: Step = .bossSelection

    let onClose: () -> Void

    var body: some View {
        Group {
            if multiplayerManager.availableRaidBosses.isEmpty {
                emptyBossState
            } else {
                switch step {
                case .bossSelection:
                    RaidBossSelectionView(
                        onSelectBoss: { boss in
                            multiplayerManager.selectRaidBoss(boss)
                            step = .lobby
                        },
                        onClose: {
                            multiplayerManager.leaveLobby()
                            onClose()
                        }
                    )
                case .lobby:
                    MultiplayerLobbyView(
                        onBack: {
                            multiplayerManager.leaveLobby()
                            step = .bossSelection
                        },
                        onClose: {
                            multiplayerManager.leaveLobby()
                            onClose()
                        }
                    )
                }
            }
        }
        .onAppear {
            multiplayerManager.ensureLocalLobbyState()
        }
    }

    private var emptyBossState: some View {
        ZStack {
            if let theme = theme.selectedTheme {
                RemoteAssetImage(theme.background) {
                    Color.black.opacity(0.4)
                }
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.7),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Keine Raid-Bossdaten geladen")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text(
                    "Die App hat aktuell keine remote raid_bosses.json geladen. Bitte pruefe Manifest, Version oder Internetverbindung."
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)

                Button(action: onClose) {
                    Text("Schliessen")
                        .font(.system(size: 15, weight: .black))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.white, in: Capsule())
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
    }
}

private struct RaidBossSelectionView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager

    let onSelectBoss: (RaidBossDefinition) -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar
                header

                ForEach(multiplayerManager.availableRaidBosses) { boss in
                    bossCard(for: boss)
                }
            }
            .padding(20)
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
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.62),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button(action: onClose) {
                Text("Schliessen")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.42), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Raid Boss Auswahl")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text(
                "Waehle zuerst den Boss. Danach kommst du in die Lobby und kannst Matchmaking oder Solo mit Bots starten."
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.82))
        }
    }

    private func bossCard(for boss: RaidBossDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(boss.name)
                        .font(.system(size: 24, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    Text(boss.summary)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("Lv \(boss.recommendedCharacterLevel)+")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow, in: Capsule())
            }

            HStack {
                Label("\(boss.maxHP) HP", systemImage: "heart.fill")
                Spacer()
                Label("\(boss.attack) ATK", systemImage: "flame.fill")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.orange)

            HStack {
                Label(
                    "Party \(boss.recommendedPartySize)",
                    systemImage: "person.3.fill"
                )
                Spacer()
                Label(
                    "Schwierigkeit \(boss.difficulty)",
                    systemImage: "bolt.fill"
                )
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))

            Button {
                onSelectBoss(boss)
            } label: {
                Text("Boss waehlen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RaidBossSelectionButtonStyle())
        }
        .padding(18)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct RaidBossSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .padding(.vertical, 14)
            .background(
                Color.white,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(.black)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
