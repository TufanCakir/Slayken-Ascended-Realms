//
//  MapSelectView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct MapSelectView: View {

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Image(gameState.selectedMap.mapImage)
                    .resizable()
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ],
                    ) {
                        ForEach(gameState.maps) { map in
                            Button {
                                gameState.saveMap(map)
                                onClose()
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    Image(map.mapImage)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 18)
                                        )
                                }
                                .overlay {
                                    if gameState.selectedMap.id == map.id {
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
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    MapSelectView(onClose: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())

}
