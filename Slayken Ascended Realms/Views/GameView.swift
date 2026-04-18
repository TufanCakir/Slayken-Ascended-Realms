//
//  GameView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
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
    @Query private var completedBattles: [PlayerBattleProgress]

    @State private var showPopup = false
    @State private var selectedEnemy: CharacterStats?
    @State private var activeSelectionSheet: ActiveSelectionSheet?
    @State private var showStory = false
    @State private var currentStory: [StoryLine] = []
    @State private var joystickVector: SIMD2<Float> = .zero
    @State private var showSupport = false
    @State private var showGlobeEvents = false
    @State private var showSummon = false
    @State private var showCharacter = false
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

                if selectedTab == .game && !showStory && !showPopup {
                    GameEventMapPreviewView(
                        chapter: gameState.activeEventChapter,
                        point: gameState.activeEventPoint,
                        completedBattleIDs: Set(completedBattles.map(\.battleID)),
                        selectedBattleID: gameState.selectedBattle?.id,
                        theme: theme.selectedTheme ?? theme.themes.first,
                        onOpen: {
                            selectedTab = .events
                            showGlobeEvents = true
                        },
                        onSelectBattle: { battle in
                            startBattle(battle)
                        }
                    )
                    .padding(.bottom, 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .zIndex(4)
                }

                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        GameHeaderView(currencies: gameState.currencies)
                            .padding()
                    }

                    Spacer()

                    // 🎮 TAB CONTENT
                    Group {
                        switch selectedTab {
                        case .game:
                            VStack {

                                JoystickView(vector: $joystickVector)
                                    .padding(.bottom, 230)
                            }

                        case .events:
                            EmptyView()

                        case .map:
                            MapSelectView {
                                selectedTab = .game
                            }
                            .environmentObject(gameState)

                        case .character:
                            EmptyView()
                        case .summon:
                            EmptyView()
                        case .support:
                            SupportView()
                        }
                    }

                    // 🔻 FOOTER IMMER UNTEN
                    GameFooterView(selectedTab: $selectedTab)

                }

                GameSideDrawerView(
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
                .frame(maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(12)

                GameMiddleDrawerView(
                    selectedTab: $selectedTab,
                    onSupport: {
                        showSupport = true
                    }
                )
                .zIndex(11)
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
                isPresented: $showCharacter,
                onDismiss: {
                    if selectedTab == .character {
                        selectedTab = .game
                    }
                }
            ) {
                CharacterSelectView(onClose: {
                    showCharacter = false
                    selectedTab = .game
                })
                .environmentObject(gameState)
                .environmentObject(theme)
                .ignoresSafeArea()
                .background(.black)
            }
            .fullScreenCover(
                isPresented: $showSummon,
                onDismiss: {
                    if selectedTab == .summon {
                        selectedTab = .game
                    }
                }
            ) {
                SummonView(
                    banners: gameState.summonBanners,
                    characters: gameState.summonCharacters,
                    currencies: gameState.currencies,
                    onClose: {
                        showSummon = false
                        selectedTab = .game
                    }
                )
                .ignoresSafeArea()
                .background(.black)
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
                        chapters: gameState.eventChapters,
                        selectedBattleID: gameState.selectedBattle?.id
                    ) { battle in
                        showGlobeEvents = false
                        selectedTab = .game
                        startBattle(battle)
                    }
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameHeaderView(currencies: gameState.currencies)

                        Spacer()

                        GameFooterView(selectedTab: $selectedTab)
                    }

                    GameSideDrawerView(
                        showBackground: false,
                        showTheme: false,
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
                    .frame(maxHeight: .infinity, alignment: .topTrailing)
                    .zIndex(12)

                    GameMiddleDrawerView(
                        selectedTab: $selectedTab,
                        onSupport: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showSupport = true
                        }
                    )
                    .zIndex(11)
                }
                .background(.black)
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .events {
                    showGlobeEvents = true
                } else if newTab == .character {
                    showCharacter = true
                } else if newTab == .summon {
                    showSummon = true
                } else {
                    if showGlobeEvents {
                        showGlobeEvents = false
                    }
                    if showCharacter {
                        showCharacter = false
                    }
                    if showSummon {
                        showSummon = false
                    }
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
        gameState.clearBattleSelection()
        gameState.selectedMap = map
        selectedEnemy = map.enemy
        currentStory = map.story

        withAnimation(.easeInOut(duration: 0.25)) {
            showPopup = false
            showStory = true
        }
    }

    private func startBattle(_ battle: GlobeBattle) {
        gameState.selectBattle(battle)
        selectedEnemy = battle.enemy
        currentStory = battle.story

        withAnimation(.easeInOut(duration: 0.25)) {
            showPopup = battle.cutscene != nil || battle.story.isEmpty
            showStory = battle.cutscene == nil && !battle.story.isEmpty
        }
    }
}

#Preview {
    GameView { _ in }
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
