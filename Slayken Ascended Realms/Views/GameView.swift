//
//  GameView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameView: View {
    private enum ActiveSelectionSheet: Identifiable {
        case background
        case map
        case theme

        var id: String {
            switch self {
            case .background:
                return "background"
            case .map:
                return "map"
            case .theme:
                return "theme"
            }
        }
    }

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    @State private var showThemeSelect = false
    @State private var showPopup = false
    @State private var startBattle = false
    @State private var selectedEnemy: CharacterStats?
    @State private var selectedPlayer: String = ""
    @State private var activeSelectionSheet: ActiveSelectionSheet?
    @State private var showStory = false
    @State private var currentStory: [StoryLine] = []

    let rows = [
        GridItem(.fixed(90)),
        GridItem(.fixed(90)),
    ]

    var body: some View {
        NavigationStack {
            GeometryReader { geo in

                ZStack {

                    if showStory {
                        StoryView(
                            story: currentStory
                        ) {
                            showStory = false
                            showPopup = true
                        }
                        .environmentObject(theme)  // 👈 DAS FEHLT
                        .transition(.opacity)
                        .zIndex(20)
                    }

                    // 🔥 POPUP OVERLAY (JETZT RICHTIG)
                    if showPopup {
                        PopupView(
                            showPopup: $showPopup,
                            startBattle: $startBattle
                        )
                        .environmentObject(theme)
                        .transition(.opacity)
                        .zIndex(10)
                    }

                    VStack(spacing: 0) {

                        // CHARACTER
                        ZStack {
                            Image(gameState.selectedBackground.image)
                                .resizable()
                                .ignoresSafeArea()

                            Image(gameState.player.image)
                                .resizable()
                                .scaledToFit()
                        }

                        // MAP
                        GeometryReader { _ in
                            ZStack {

                                Image(gameState.selectedMap.mapImage)
                                    .resizable()
                                    .ignoresSafeArea()

                                // 🔥 LEVEL BUTTONS
                                VStack {

                                    ScrollView(
                                        .horizontal,
                                        showsIndicators: false
                                    ) {

                                        LazyHGrid(rows: rows, spacing: 16) {

                                            ForEach(gameState.maps) { map in
                                                levelButton(map: map)
                                            }
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                        .frame(height: geo.size.height * 0.55)
                    }
                }
                .fullScreenCover(isPresented: $startBattle) {
                    if let enemy = selectedEnemy {
                        BattleView(
                            player: gameState.player,
                            enemy: enemy
                        )
                        .environmentObject(gameState)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {

                        Button {
                            activeSelectionSheet = .background
                        } label: {
                            Image(systemName: "photo")
                        }

                        Button {
                            activeSelectionSheet = .map
                        } label: {
                            Image(systemName: "map")
                        }
                        Button {
                            activeSelectionSheet = .theme
                        } label: {
                            Image(systemName: "paintbrush")
                        }
                    }
                }
                .sheet(item: $activeSelectionSheet) { selection in
                    switch selection {
                    case .background:
                        BackgroundSelectView {
                            activeSelectionSheet = nil
                        }
                        .environmentObject(gameState)
                    case .map:
                        MapSelectView {
                            activeSelectionSheet = nil
                        }
                        .environmentObject(gameState)
                    case .theme:
                        ThemeSelectView {
                            activeSelectionSheet = nil
                        }
                        .environmentObject(theme)
                    }
                }
            }
        }
    }

    private func levelButton(map: GameMap) -> some View {
        Button {
            gameState.selectedMap = map
            selectedEnemy = map.enemy

            currentStory = map.story
            showPopup = false
            showStory = true

        } label: {
            ZStack(alignment: .bottomLeading) {

                // 🖼️ BACKGROUND IMAGE
                Image(map.mapImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 100)
                    .clipped()

                // 📝 TEXT
                Text(map.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: 180, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            // 🔥 SELECTED BORDER
            .overlay {
                if gameState.selectedMap.id == map.id {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white, lineWidth: 3)
                }
            }
        }
    }
}

#Preview {
    GameView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
