//
//  StartView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import SwiftUI

struct StartView: View {

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onStart: () -> Void

    var body: some View {
        ZStack {

            Image("warrior_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 20) {

                Text("Slayken")
                    .font(.system(size: 40, weight: .black))
                    .shadow(color: .black, radius: 5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color ?? .blue,
                                theme.selectedTheme?.secondary.color ?? .cyan,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Ascended Realms")
                    .font(.system(size: 40, weight: .black))
                    .shadow(color: .black, radius: 5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.selectedTheme?.primary.color ?? .blue,
                                theme.selectedTheme?.secondary.color ?? .cyan,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onStart()
        }
    }
}

#Preview {
    StartView(onStart: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
