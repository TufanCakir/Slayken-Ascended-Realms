//
//  BattleComboLibraryView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 29.05.26.
//

import SwiftUI

struct BattleComboLibraryView: View {
    let combos: [BattleComboDefinition]
    let activeComboID: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(combos) { combo in
                        comboCard(combo)
                    }
                }
                .padding(16)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.12, green: 0.02, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Combos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }

    private func comboCard(_ combo: BattleComboDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Text(combo.displayName.uppercased())
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if combo.id == activeComboID {
                            Text("AKTIV")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.yellow, in: Capsule())
                                .foregroundStyle(.black)
                        }
                    }

                    Text(combo.displayDescription)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("\(combo.steps.count) HIT")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.12), in: Capsule())
                    .foregroundStyle(.white)
            }

            inputSequence(combo.resolvedInputSequence)

            VStack(spacing: 8) {
                ForEach(Array(combo.steps.enumerated()), id: \.element.id) {
                    index,
                    step in
                    comboStepRow(index: index, step: step)
                }
            }
        }
        .padding(14)
        .background(
            Color.black.opacity(0.54),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    combo.id == activeComboID
                        ? .yellow.opacity(0.8) : .white.opacity(0.14),
                    lineWidth: combo.id == activeComboID ? 1.5 : 1
                )
        }
    }

    private func inputSequence(_ inputs: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(inputs.enumerated()), id: \.offset) { _, input in
                Text(inputLabel(input))
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(inputColor(input).opacity(0.84), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comboStepRow(
        index: Int,
        step: BattleComboStepDefinition
    ) -> some View {
        HStack(spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .black))
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.12), in: Circle())
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 3) {
                Text(step.displayLabel.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                Text("\(inputLabel(step.resolvedInput))  \(step.resolvedStyle.rawValue)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            Text("x\(String(format: "%.2f", step.resolvedDamageMultiplier))")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(step.isSlowMotion ? .yellow : .cyan)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
    }

    private func inputLabel(_ input: String) -> String {
        switch input {
        case "tap":
            return "TAP"
        case "hold":
            return "HOLD"
        case "swipeUp":
            return "UP"
        case "swipeDown":
            return "DOWN"
        case "swipeLeft":
            return "LEFT"
        case "swipeRight":
            return "RIGHT"
        default:
            return input.uppercased()
        }
    }

    private func inputColor(_ input: String) -> Color {
        switch input {
        case "tap":
            return .blue
        case "hold":
            return .orange
        case "swipeUp":
            return .green
        case "swipeDown":
            return .red
        case "swipeLeft", "swipeRight":
            return .purple
        default:
            return .gray
        }
    }
}
