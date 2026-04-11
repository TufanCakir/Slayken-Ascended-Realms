//
//  PopupView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import SwiftUI

struct PopupView: View {
    @Binding var showPopup: Bool
    @Binding var startBattle: Bool

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Kampf starten?")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 12) {
                    Button {
                        showPopup = false
                    } label: {
                        Text("Abbrechen")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showPopup = false
                        startBattle = true
                    } label: {
                        Text("Start")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        theme.selectedTheme?.primary.color
                                            ?? .blue,
                                        theme.selectedTheme?.secondary.color
                                            ?? .cyan,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(
                                color: (theme.selectedTheme?.glow.color ?? .blue)
                                    .opacity(0.6),
                                radius: 10
                            )
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        theme.selectedTheme?.accent.color ?? .black,
                        (theme.selectedTheme?.accent.color ?? .black).opacity(
                            0.7
                        ),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        theme.selectedTheme?.primary.color ?? .blue,
                        lineWidth: 2
                    )
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    PopupView(showPopup: .constant(true), startBattle: .constant(false))
        .environmentObject(ThemeManager())
}
