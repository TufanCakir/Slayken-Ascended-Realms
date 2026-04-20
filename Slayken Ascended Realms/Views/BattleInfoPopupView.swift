//
//  BattleInfoPopupView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct BattleInfoPopupView: View {
    @Binding var showPopup: Bool

    let battle: GlobeBattle
    let onStart: () -> Void

    @EnvironmentObject private var theme: ThemeManager

    private var mainEnemy: CharacterStats {
        battle.primaryEnemy
    }

    private var enemyElement: GameElement {
        GameElement(mainEnemy.element)
    }

    private var enemyLevel: Int {
        max(1, battle.difficulty * 5 + enemyCount * 2)
    }

    private var enemyStars: Int {
        min(5, max(1, battle.difficulty + (battle.boss == nil ? 0 : 1)))
    }

    private var enemyPower: Int {
        Int((mainEnemy.hp + mainEnemy.attack * 10).rounded())
    }

    private var enemyCount: Int {
        battle.battleEnemies.count
    }

    private var recommendedElements: [GameElement] {
        GameElement.allCases.filter { element in
            element.multiplier(against: enemyElement) > 1.0
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                enemySummary
                statGrid
                elementTips
                actionRow
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background(
                LinearGradient(
                    colors: [
                        theme.selectedTheme?.accent.color.opacity(0.96)
                            ?? Color.black.opacity(0.96),
                        Color.black.opacity(0.88),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        theme.selectedTheme?.primary.color
                            ?? enemyElement.color,
                        lineWidth: 2
                    )
            }
            .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
            .padding(.horizontal, 18)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Battle Info")
                .font(.system(size: 11, weight: .black))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.62))

            Text(battle.name)
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(battle.description)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(2)
        }
    }

    private var enemySummary: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(enemyElement.color.opacity(0.18))
                    .frame(width: 58, height: 58)
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(enemyElement.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mainEnemy.name)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(enemyElement.displayName)
                        .foregroundStyle(enemyElement.color)
                    Text("Lv.\(enemyLevel)")
                    Text(String(repeating: "★", count: enemyStars))
                        .foregroundStyle(.yellow)
                }
                .font(.system(size: 11, weight: .black))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private var statGrid: some View {
        HStack(spacing: 8) {
            statBadge(title: "POWER", value: "\(enemyPower)")
            statBadge(title: "HP", value: "\(Int(mainEnemy.hp))")
            statBadge(title: "ATK", value: "\(Int(mainEnemy.attack))")
            statBadge(title: "WAVES", value: "\(enemyCount)")
        }
    }

    private func statBadge(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            Color.black.opacity(0.30),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private var elementTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Effektiv gegen diesen Gegner")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white.opacity(0.62))

            HStack(spacing: 7) {
                ForEach(recommendedElements.prefix(4), id: \.self) { element in
                    Text(element.displayName)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.black.opacity(0.78))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(element.color, in: Capsule())
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                showPopup = false
            } label: {
                Text("Abbrechen")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Color.white.opacity(0.10),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                showPopup = false
                onStart()
            } label: {
                Text("Start")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color
                                    ?? enemyElement.color,
                                theme.selectedTheme?.secondary.color ?? .cyan,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }
}

#Preview {
    BattleInfoPopupView(
        showPopup: .constant(true),
        battle: loadGlobeEventChapters().first!.points.first!.battles.first!,
        onStart: {}
    )
    .environmentObject(ThemeManager())
}
