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

    @State private var showPopup = false
    @State private var selectedEnemy: CharacterStats?
    @State private var activeSelectionSheet: ActiveSelectionSheet?
    @State private var showStory = false
    @State private var currentStory: [StoryLine] = []
    @State private var joystickVector: SIMD2<Float> = .zero
    @State private var showSupport = false
    @State private var selectedTab: GameTab = .game
    
    let onStartBattle: (CharacterStats) -> Void

    let rows = [
        GridItem(.fixed(90)),
        GridItem(.fixed(90)),
    ]

    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                
                
                // ✅ 3D FULLSCREEN
                GameSceneView(
                    player: gameState.player,
                    joystickVector: joystickVector,
                    groundTexture: gameState.selectedMap.mapImage,
                    skyboxTexture: gameState.selectedBackground.image
                )
                .id(gameState.player.model)
                .ignoresSafeArea()
                
                
                if showStory {
                    StoryView(story: currentStory) {
                        withAnimation {
                            showStory = false
                            showPopup = true
                        }
                    }
                    .zIndex(20)
                }

                if showPopup {
                    PopupView(showPopup: $showPopup) {
                        if let selectedEnemy {
                            onStartBattle(selectedEnemy)
                        }
                    }
                    .zIndex(30)
                }

                VStack(spacing: 0) {
                    GameHeaderView(
                        onBackground: {
                            activeSelectionSheet = .background
                        },
                        onMap: {
                            activeSelectionSheet = .map
                        },
                        onTheme: {
                            activeSelectionSheet = .theme
                        },
                        onSupport: {
                            showSupport = true
                        }
                    )

                    Spacer()

                    // 🎮 TAB CONTENT
                    Group {
                        switch selectedTab {
                        case .game:
                            VStack {

                                JoystickView(vector: $joystickVector)
                                    .padding(.bottom, 12)

                                mapScrollSection(geo: geo)
                            }

                        case .map:
                            MapSelectView {
                                selectedTab = .game
                            }
                            .environmentObject(gameState)

                        case .character:
                            CharacterSelectView()
                        }
                    }

                    // 🔻 FOOTER IMMER UNTEN
                    GameFooterView(selectedTab: $selectedTab)
                
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
            .sheet(isPresented: $showSupport) {
                SupportView()
            }
        }
    }
    
    private func mapScrollSection(geo: GeometryProxy) -> some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: 16) {
                    ForEach(gameState.maps) { map in
                        levelButton(map: map)
                    }
                }
                .padding()
            }
        }
        .frame(height: geo.size.height * 0.25)
        .background(.ultraThinMaterial)
    }

    private func levelButton(map: GameMap) -> some View {
        Button {
            gameState.selectedMap = map
            selectedEnemy = map.enemy
            currentStory = map.story

            withAnimation(.easeInOut(duration: 0.25)) {
                showPopup = false
                showStory = true
            }
        } label: {
            ZStack(alignment: .bottomLeading) {

                Image(map.mapImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 100)
                    .clipped()

                Text(map.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: 180, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))
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
    GameView { _ in }
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
