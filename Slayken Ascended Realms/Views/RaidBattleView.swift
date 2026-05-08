//
//  RaidBattleView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct RaidBattleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager

    let onClose: () -> Void

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    topBar

                    Text(multiplayerManager.activeRaid?.boss.name ?? "Raid")
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    if let raid = multiplayerManager.activeRaid {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Boss HP")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)

                            ProgressView(value: raid.bossHealthProgress)
                                .tint(.orange)

                            Text("\(raid.bossHP) / \(raid.boss.maxHP)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .padding(18)
                        .background(.white.opacity(0.1))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                        )

                        Button {
                            multiplayerManager.performLocalAttack()
                        } label: {
                            Text("Probe-Angriff senden")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 16, weight: .black))
                                .padding(.vertical, 16)
                                .background(
                                    .white,
                                    in: RoundedRectangle(
                                        cornerRadius: 18,
                                        style: .continuous
                                    )
                                )
                                .foregroundStyle(.black)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Combat Log")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.white)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(
                                        Array(raid.combatLog.enumerated()),
                                        id: \.offset
                                    ) { _, entry in
                                        Text(entry)
                                            .font(
                                                .system(
                                                    size: 13,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundStyle(
                                                .white.opacity(0.82)
                                            )
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(.white.opacity(0.1))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                        )
                    }

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            if let backgroundAsset = theme.selectedTheme?.background,
                !backgroundAsset.isEmpty
            {
                RemoteAssetImage(backgroundAsset) {
                    Color.black.opacity(0.35)
                }
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
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

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
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
}
