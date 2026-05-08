//
//  MultiplayerLobbyView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct MultiplayerLobbyView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager

    let onBack: () -> Void
    let onClose: () -> Void

    var body: some View {

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar
                header
                bossCard
                partyCard
                statusCard
                actionButtons
                Spacer(minLength: 0)
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

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.black.opacity(0.42), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onClose) {
                Text("Schliessen")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Color.black.opacity(0.42),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coop Raid Lobby")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(.white)

            Text(
                "Der Boss ist gewaehlt. Jetzt Matchmaking starten oder solo mit Bots in den Raid gehen."
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var bossCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let boss = multiplayerManager.lobbyState?.boss {
                Text(boss.name)
                    .font(.system(size: 24, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text(boss.summary)
                    .foregroundStyle(.white.opacity(0.78))

                HStack {
                    Label("\(boss.maxHP) HP", systemImage: "flame.fill")
                    Spacer()
                    Label(
                        "Empfohlen: \(boss.recommendedPartySize)",
                        systemImage: "person.3.fill"
                    )
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.orange)

                Label(
                    "Ab Charakter-Level \(boss.recommendedCharacterLevel)",
                    systemImage: "star.circle.fill"
                )
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.yellow)
            } else {
                Text("Keine Raid-Bossdaten geladen")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text(
                    "Ohne geladene remote raid_bosses.json kann keine Lobby aufgebaut werden."
                )
                .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var partyCard: some View {
        let participants = multiplayerManager.lobbyState?.participants ?? []

        return VStack(alignment: .leading, spacing: 12) {
            Text("Gruppe")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)

            ForEach(participants) { participant in
                participantRow(participant)
            }
        }
        .padding(18)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.white)

            Text(
                multiplayerManager.lobbyState?.statusText
                    ?? "Noch keine Lobby aktiv."
            )
            .foregroundStyle(.white.opacity(0.78))

            if let lastErrorMessage = multiplayerManager.lastErrorMessage,
                !lastErrorMessage.isEmpty
            {
                Text(lastErrorMessage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
        .padding(18)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                multiplayerManager.startRaidMatchmaking()
            } label: {
                Text(
                    multiplayerManager.isMatchmaking
                        ? "Matchmaking aktiv" : "Raid finden"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbyPrimaryButtonStyle())
            .disabled(multiplayerManager.isMatchmaking)

            Button {
                multiplayerManager.toggleReadyState()
            } label: {
                Text("Bereitschaft umschalten")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbySecondaryButtonStyle())

            Button {
                multiplayerManager.startRaidIfPossible()
            } label: {
                Text("Raid starten")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbyPrimaryButtonStyle())
            .disabled(!(multiplayerManager.lobbyState?.canStartRaid ?? false))

            Button {
                multiplayerManager.startSoloRaidWithBots()
            } label: {
                Text("Solo mit Bots")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbySecondaryButtonStyle())

            Button {
                multiplayerManager.leaveLobby()
                onBack()
            } label: {
                Text("Boss wechseln")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbySecondaryButtonStyle())

            Button {
                multiplayerManager.leaveLobby()
            } label: {
                Text("Lobby verlassen")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LobbySecondaryButtonStyle())
        }
    }

    private func label(for participant: RaidParticipant) -> String {
        if participant.isBot {
            return "Bot"
        }
        if participant.isLocalPlayer {
            return participant.isHost ? "Du • Host" : "Du"
        }
        return participant.isHost
            ? "Host" : participant.connectionState.rawValue.capitalized
    }

    private func participantRow(_ participant: RaidParticipant) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Text(label(for: participant))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    if let roleName = participant.roleName {
                        Text(roleName)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.cyan.opacity(0.88))
                    }
                }

                Spacer()

                Text(
                    participant.isBot
                        ? "Bot" : participant.isReady ? "Ready" : "Open"
                )
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(
                    participant.isBot
                        ? .cyan : participant.isReady ? .green : .yellow
                )
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                8,
                                proxy.size.width
                                    * CGFloat(participant.healthProgress)
                            )
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("HP \(participant.currentHP)/\(participant.maxHP)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))

                Spacer()

                Text(participant.connectionState.rawValue.capitalized)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.6))
            }

            if let roleSummary = participant.roleSummary {
                Text(roleSummary)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LobbyPrimaryButtonStyle: ButtonStyle {
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

private struct LobbySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .padding(.vertical, 14)
            .background(
                Color.white.opacity(0.14),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(.white)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
