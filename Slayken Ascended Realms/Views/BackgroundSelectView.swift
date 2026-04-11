//
//  BackgroundSelectView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct BackgroundSelectView: View {

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Image(gameState.selectedBackground.image)
                    .resizable()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                    ) {
                        ForEach(gameState.backgrounds) { bg in
                            Button {
                                gameState.saveBackground(bg)
                                onClose()
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    Image(bg.image)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 18)
                                        )
                                }
                                .overlay {
                                    if gameState.selectedBackground.id == bg.id
                                    {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                theme.selectedTheme?.primary
                                                    .color ?? .blue,
                                                lineWidth: 3
                                            )
                                            .shadow(
                                                color: (theme.selectedTheme?
                                                    .glow.color ?? .blue)
                                                    .opacity(0.8),
                                                radius: 10
                                            )
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    BackgroundSelectView(onClose: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
