//
//  TutorialArchiveView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct TutorialArchiveView: View {
    let tutorials: [GameTutorialDefinition]
    let onClose: () -> Void
    let onReplay: (GameTutorialDefinition) -> Void

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    ForEach(tutorials) { tutorial in
                        tutorialCard(tutorial)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
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
                        Color.black.opacity(0.22),
                        Color.black.opacity(0.66),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        .white.opacity(0.13),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("TUTORIAL ARCHIV")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                Text("Bereits abgeschlossene Tutorials erneut spielen")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer(minLength: 0)

            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.cyan)
                .frame(width: 40, height: 40)
                .background(
                    .white.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private func tutorialCard(_ tutorial: GameTutorialDefinition) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(tutorial.title.uppercased())
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)

                Text(tutorial.objective)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                infoPill(title: "Held", value: tutorial.player.name)
                infoPill(
                    title: "Gegner",
                    value: tutorialEnemySummary(for: tutorial)
                )
            }

            Button {
                onReplay(tutorial)
            } label: {
                Text("TUTORIAL STARTEN")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [.cyan.opacity(0.95), .blue.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .white.opacity(0.075),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
    }

    private func tutorialEnemySummary(for tutorial: GameTutorialDefinition)
        -> String
    {
        if let boss = tutorial.boss {
            return "\(tutorial.allEnemies.count)x inkl. \(boss.name)"
        }

        if tutorial.allEnemies.count == 1 {
            return tutorial.allEnemies.first?.name ?? "-"
        }

        return "\(tutorial.allEnemies.count)x Gegner"
    }
}

#Preview {
    TutorialArchiveView(
        tutorials: loadTutorialDefinitions(),
        onClose: {},
        onReplay: { _ in }
    )
    .environmentObject(ThemeManager())
}
