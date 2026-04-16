//
//  LoadingOverlayView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 13.04.26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let progress: Double
    let background: String

    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let goldTop = Color(red: 0.90, green: 0.79, blue: 0.48)
        let goldBottom = Color(red: 0.42, green: 0.28, blue: 0.11)

        ZStack {
            // Background
            Image(background)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.85),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // CENTERED PANEL
            VStack {
                Spacer()

                VStack(spacing: 20) {

                    Text("LOADING REALM")
                        .font(
                            .system(size: 22, weight: .black, design: .rounded)
                        )
                        .tracking(1.5)
                        .foregroundStyle(.white)

                    VStack(spacing: 12) {

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {

                                // Background
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.95),
                                                Color(
                                                    red: 0.16,
                                                    green: 0.17,
                                                    blue: 0.18
                                                ),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Progress Fill
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                theme.selectedTheme?.primary
                                                    .color ?? .green,
                                                theme.selectedTheme?.secondary
                                                    .color ?? .blue,
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(
                                            20,
                                            geo.size.width * progress
                                        )
                                    )
                                    .padding(4)
                                    .animation(
                                        .easeInOut(duration: 0.25),
                                        value: progress
                                    )

                                    // ✨ Shine Effekt
                                    .overlay(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                .clear,
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .cornerRadius(8)
                                        .padding(4)
                                    )

                                // Gold Border
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        LinearGradient(
                                            colors: [goldTop, goldBottom],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 2
                                    )

                                // Inner Glow
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        Color.white.opacity(0.15),
                                        lineWidth: 1
                                    )
                                    .padding(2)
                            }
                        }
                        .frame(height: 20)

                        Text("\(Int(progress * 100))%")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.92),
                            Color(red: 0.11, green: 0.12, blue: 0.14),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [goldTop, goldBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.7), radius: 30, y: 12)
                .frame(maxWidth: 420)
                .padding(.horizontal, 24)
                Spacer()
            }
        }
    }
}
#Preview {
    LoadingOverlayView(progress: 100, background: "")
        .environmentObject(ThemeManager())
}
