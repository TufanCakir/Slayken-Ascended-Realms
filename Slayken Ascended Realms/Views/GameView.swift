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
    @State private var showGlobeEvents = false
    @State private var selectedTab: GameTab = .game

    let onStartBattle: (CharacterStats) -> Void

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
                            }

                        case .events:
                            EmptyView()

                        case .map:
                            MapSelectView {
                                selectedTab = .game
                            }
                            .environmentObject(gameState)

                        case .character:
                            CharacterSelectView()
                        case .support:
                            SupportView()
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
            .fullScreenCover(
                isPresented: $showGlobeEvents,
                onDismiss: {
                    if selectedTab == .events {
                        selectedTab = .game
                    }
                }
            ) {
                ZStack {
                    GlobeEventView(
                        maps: gameState.maps,
                        selectedMap: gameState.selectedMap
                    ) { map in
                        showGlobeEvents = false
                        selectedTab = .game
                        startMap(map)
                    }
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameHeaderView(
                            onBackground: {
                                closeGlobeAndOpen(.background)
                            },
                            onMap: {
                                closeGlobeAndOpen(.map)
                            },
                            onTheme: {
                                closeGlobeAndOpen(.theme)
                            },
                            onSupport: {
                                showGlobeEvents = false
                                selectedTab = .game
                                showSupport = true
                            }
                        )

                        Spacer()

                        GameFooterView(selectedTab: $selectedTab)
                    }
                }
                .background(.black)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .events {
                    showGlobeEvents = true
                } else if showGlobeEvents {
                    showGlobeEvents = false
                }
            }
        }
    }

    private func closeGlobeAndOpen(_ selection: ActiveSelectionSheet) {
        showGlobeEvents = false
        selectedTab = .game
        activeSelectionSheet = selection
    }

    private func startMap(_ map: GameMap) {
        gameState.selectedMap = map
        selectedEnemy = map.enemy
        currentStory = map.story

        withAnimation(.easeInOut(duration: 0.25)) {
            showPopup = false
            showStory = true
        }
    }
}

#Preview {
    GameView { _ in }
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
