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
        case theme

        var id: String {
            switch self {
            case .theme:
                return "theme"
            }
        }
    }

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager
    @Query private var completedBattles: [PlayerBattleProgress]
    @Query private var accountProgress: [PlayerAccountProgress]

    @State private var showPopup = false
    @State private var selectedEnemy: CharacterStats?
    @State private var activeSelectionSheet: ActiveSelectionSheet?
    @State private var showStory = false
    @State private var currentStory: [StoryLine] = []
    @State private var joystickVector: SIMD2<Float> = .zero
    @State private var autoMoveTarget: SIMD2<Float>?
    @State private var showSupport = false
    @State private var showNews = false
    @State private var showStoryArchive = false
    @State private var showSettings = false
    @State private var showGlobeEvents = false
    @State private var showSummon = false
    @State private var showCharacter = false
    @State private var selectedTab: GameTab = .game

    let onResetGame: () -> Void
    let onStartBattle: (CharacterStats) -> Void

    init(
        onResetGame: @escaping () -> Void = {},
        onStartBattle: @escaping (CharacterStats) -> Void
    ) {
        self.onResetGame = onResetGame
        self.onStartBattle = onStartBattle
    }

    var body: some View {
        GeometryReader { geo in

            ZStack {

                // ✅ 3D FULLSCREEN
                GameSceneView(
                    player: gameState.player,
                    joystickVector: joystickVector,
                    autoMoveTarget: autoMoveTarget,
                    groundTexture: gameState.activeGroundTexture,
                    skyboxTexture: gameState.activeSkyboxTexture
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

                if showPopup, let battle = gameState.selectedBattle {
                    BattleInfoPopupView(
                        showPopup: $showPopup,
                        battle: battle
                    ) {
                        if let selectedEnemy {
                            onStartBattle(selectedEnemy)
                        }
                    }
                    .zIndex(30)
                }
                if selectedTab == .game && !showStory && !showPopup {
                    ZStack {
                        if let chapter = activePreviewChapter {
                            GameEventMapPreviewView(
                                chapter: chapter,
                                point: activePreviewPoint(for: chapter),
                                completedBattleIDs: Set(
                                    completedBattles.map(\.battleID)
                                ),
                                selectedBattleID: gameState.activeEventBattleID
                                    ?? gameState.selectedBattle?.id,
                                theme: theme.selectedTheme
                                    ?? theme.themes.first,
                                onSelectPoint: { _ in
                                    selectedTab = .events
                                    showGlobeEvents = true
                                },
                                onSelectBattle: { battle in
                                    moveToBattleAndStart(battle)
                                }
                            )
                            .padding(.top, 400)
                        } else {
                            EmptyView()
                                .padding(.top, 400)
                        }
                    }
                    .zIndex(4)
                }

                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        GameHeaderView(currencies: gameState.currencies) {
                            showNews = true
                        }
                        .padding()
                    }
                    .zIndex(8)

                    Spacer()

                    // 🎮 TAB CONTENT
                    Group {
                        switch selectedTab {
                        case .game:
                            EmptyView()

                        case .events:
                            EmptyView()

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
                        .zIndex(10)

                }
                .zIndex(6)

                GameSideDrawerView(
                    onTheme: {
                        activeSelectionSheet = .theme
                    },
                    onSupport: {
                        showSupport = true
                    },
                    onNews: {
                        showNews = true
                    },
                    onSettings: {
                        showSettings = true
                    }
                )
                .frame(maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(12)

                GameMiddleDrawerView(
                    selectedTab: $selectedTab,
                    onSupport: {
                        showSupport = true
                    },
                    onNews: {
                        showNews = true
                    },
                    onArchive: {
                        showStoryArchive = true
                    },
                    onSettings: {
                        showSettings = true
                    }
                )
                .offset(y: -112)
                .zIndex(11)
            }
            .sheet(item: $activeSelectionSheet) { selection in
                switch selection {

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
            .fullScreenCover(isPresented: $showNews) {
                NewsView {
                    showNews = false
                }
                .ignoresSafeArea()
                .background(.black)
            }
            .fullScreenCover(isPresented: $showStoryArchive) {
                StoryArchiveView(chapters: gameState.eventChapters) {
                    showStoryArchive = false
                }
                .environmentObject(theme)
                .ignoresSafeArea()
                .background(.black)
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(
                    onClose: {
                        showSettings = false
                    },
                    onReset: {
                        showSettings = false
                        onResetGame()
                    }
                )
                .environmentObject(gameState)
                .background(.black)
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
                        selectedBattleID: gameState.activeEventBattleID
                            ?? gameState.selectedBattle?.id
                    ) { battle in
                        showGlobeEvents = false
                        selectedTab = .game
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            moveToBattleAndStart(battle)
                        }
                    }
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer()

                        GameFooterView(selectedTab: $selectedTab)
                    }

                    GameSideDrawerView(
                        showTheme: false,
                        onTheme: {
                            closeGlobeAndOpen(.theme)
                        },
                        onSupport: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showSupport = true
                        },
                        onNews: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showNews = true
                        },
                        onSettings: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showSettings = true
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
                        },
                        onNews: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showNews = true
                        },
                        onArchive: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showStoryArchive = true
                        },
                        onSettings: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showSettings = true
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

    private var completedBattleIDs: Set<String> {
        Set(completedBattles.map(\.battleID))
    }

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    private var activePreviewChapter: GlobeEventChapter? {
        if let chapter = gameState.activeEventChapter,
           isChapterUnlocked(chapter) {
            return chapter
        }
        return gameState.eventChapters.first { isChapterUnlocked($0) }
    }

    private func activePreviewPoint(for chapter: GlobeEventChapter) -> GlobeEventPoint? {
        if chapter.id == gameState.activeEventChapterID,
           let point = gameState.activeEventPoint {
            return point
        }
        return chapter.points.first
    }

    private func isChapterUnlocked(_ chapter: GlobeEventChapter) -> Bool {
        guard ascendedLevel >= (chapter.minAscendedLevel ?? 1) else {
            return false
        }
        guard !isEventChapter(chapter) else { return true }

        guard let index = gameState.eventChapters.firstIndex(where: { $0.id == chapter.id })
        else {
            return false
        }
        guard index > 0 else { return true }

        let previousChapter = gameState.eventChapters[index - 1]
        let requiredBattleIDs = previousChapter.points.flatMap { point in
            point.battles.map(\.id)
        }
        return requiredBattleIDs.allSatisfy { completedBattleIDs.contains($0) }
    }

    private func isEventChapter(_ chapter: GlobeEventChapter) -> Bool {
        chapter.id.hasPrefix("event_")
    }

    private func moveToBattleAndStart(_ battle: GlobeBattle) {
        autoMoveTarget = sceneTarget(for: battle.node)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            autoMoveTarget = nil
            startBattle(battle)
        }
    }

    private func sceneTarget(for node: EventMapNodePosition) -> SIMD2<Float> {
        SIMD2<Float>(
            Float(node.x - 0.5) * 70,
            Float(0.5 - node.y) * 70
        )
    }

    private func startBattle(_ battle: GlobeBattle) {
        gameState.selectBattle(battle)
        selectedEnemy = battle.primaryEnemy
        currentStory = battle.story

        withAnimation(.easeInOut(duration: 0.25)) {
            showStory = !battle.story.isEmpty
            showPopup = battle.story.isEmpty
        }
    }
}

#Preview {
    GameView(onStartBattle: { _ in })
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
