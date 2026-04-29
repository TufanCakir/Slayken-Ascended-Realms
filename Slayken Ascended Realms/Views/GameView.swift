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
    @Environment(\.modelContext) private var modelContext
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
    @State private var showEventArchive = false
    @State private var showSettings = false
    @State private var showGlobeEvents = false
    @State private var showSummon = false
    @State private var showShop = false
    @State private var showQuests = false
    @State private var showCharacter = false
    @State private var showCreateClass = false
    @State private var showGift = false
    @State private var showDailyLogin = false
    @State private var selectedTab: GameTab = .game
    @State private var resourceRefreshDate = Date()
    @State private var battleResourceMessage = ""

    private let gifts = loadGiftBoxDefinitions()
    private let dailyLoginRewards = loadDailyLoginRewardDefinitions()
    private let quests = loadQuestDefinitions()

    let onResetGame: () -> Void
    let onOpenTutorialArchive: () -> Void
    let onOpenCreateClass: () -> Void
    let onStartBattle: (CharacterStats) -> Void

    init(
        onResetGame: @escaping () -> Void = {},
        onOpenTutorialArchive: @escaping () -> Void = {},
        onOpenCreateClass: @escaping () -> Void = {},
        onStartBattle: @escaping (CharacterStats) -> Void
    ) {
        self.onResetGame = onResetGame
        self.onOpenTutorialArchive = onOpenTutorialArchive
        self.onOpenCreateClass = onOpenCreateClass
        self.onStartBattle = onStartBattle
    }

    var body: some View {
        GeometryReader { geo in
            let horizontalOverlayPadding: CGFloat = 16

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
                        startSelectedBattleIfPossible()
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
                    GameHeaderView(
                        currencies: gameState.currencies,
                        ascendedLevel: ascendedLevel,
                        ascendedXP: ascendedXP,
                        horizontalPadding: horizontalOverlayPadding
                    ) {
                        showNews = true
                    }
                    .zIndex(8)

                    battleResourceBar
                        .padding(.horizontal, horizontalOverlayPadding)
                        .padding(.top, 10)

                    if !battleResourceMessage.isEmpty {
                        Text(battleResourceMessage)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, horizontalOverlayPadding)
                            .padding(.top, 8)
                    }

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
                        case .shop:
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

                GameMiddleDrawerView(
                    selectedTab: $selectedTab,
                    onTheme: {
                        activeSelectionSheet = .theme
                    },
                    onSupport: {
                        showSupport = true
                    },
                    onNews: {
                        showNews = true
                    },
                    onCreateClass: {
                        showCreateClass = true
                    },
                    onShop: {
                        showShop = true
                    },
                    onQuests: {
                        showQuests = true
                    },
                    onArchive: {
                        showStoryArchive = true
                    },
                    onEventArchive: {
                        showEventArchive = true
                    },
                    onTutorialArchive: {
                        onOpenTutorialArchive()
                    },
                    onGift: {
                        showGift = true
                    },
                    onDailyLogin: {
                        showDailyLogin = true
                    },
                    onSettings: {
                        showSettings = true
                    },
                    trailingPadding: horizontalOverlayPadding
                )
                .offset(y: -10)
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
            .fullScreenCover(isPresented: $showGift) {
                GiftView(
                    gifts: gifts,
                    onClaim: claimGiftFromMenu,
                    onClose: {
                        showGift = false
                    }
                )
                .environmentObject(gameState)
                .environmentObject(theme)
                .background(.black)
            }
            .fullScreenCover(isPresented: $showDailyLogin) {
                DailyLoginView(
                    rewards: dailyLoginRewards,
                    currencies: gameState.currencies,
                    availableReward: availableDailyReward,
                    onClaim: claimDailyGiftFromMenu,
                    onClose: {
                        showDailyLogin = false
                    }
                )
                .background(.black)
            }
            .fullScreenCover(isPresented: $showStoryArchive) {
                StoryArchiveView(chapters: storyArchiveChapters) {
                    showStoryArchive = false
                }
                .environmentObject(theme)
                .background(.black)
            }
            .fullScreenCover(isPresented: $showEventArchive) {
                EventArchiveView(chapters: eventArchiveChapters) {
                    showEventArchive = false
                }
                .environmentObject(theme)
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
                    },
                    onOpenTutorialArchive: {
                        showSettings = false
                        onOpenTutorialArchive()
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
                .background(.black)
            }
            .fullScreenCover(isPresented: $showCreateClass) {
                CreateClassView(
                    onClose: {
                        showCreateClass = false
                    },
                    onComplete: { character in
                        gameState.saveCharacter(character)
                        showCreateClass = false
                        onOpenCreateClass()
                    }
                )
                .environmentObject(gameState)
                .environmentObject(theme)
                .ignoresSafeArea()
                .background(.black)
            }
            .fullScreenCover(isPresented: $showShop) {
                ShopView(onClose: {
                    showShop = false
                })
                .environmentObject(gameState)
                .environmentObject(theme)
                .background(.black)
            }
            .fullScreenCover(isPresented: $showQuests) {
                QuestView(
                    quests: quests,
                    onClose: {
                        showQuests = false
                    }
                )
                .environmentObject(gameState)
                .environmentObject(theme)
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

                    GameMiddleDrawerView(
                        selectedTab: $selectedTab,
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
                        onCreateClass: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showCreateClass = true
                        },
                        onShop: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showShop = true
                        },
                        onQuests: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showQuests = true
                        },
                        onArchive: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showStoryArchive = true
                        },
                        onEventArchive: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showEventArchive = true
                        },
                        onTutorialArchive: {
                            showGlobeEvents = false
                            selectedTab = .game
                            onOpenTutorialArchive()
                        },
                        onGift: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showGift = true
                        },
                        onDailyLogin: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showDailyLogin = true
                        },
                        onSettings: {
                            showGlobeEvents = false
                            selectedTab = .game
                            showSettings = true
                        },
                        trailingPadding: horizontalOverlayPadding
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
                } else if newTab == .shop {
                    showShop = true
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
                    if showShop {
                        showShop = false
                    }
                }
            }
            .task {
                while !Task.isCancelled {
                    resourceRefreshDate = .now
                    try? await Task.sleep(for: .seconds(20))
                }
            }
        }
    }

    private func closeGlobeAndOpen(_ selection: ActiveSelectionSheet) {
        showGlobeEvents = false
        selectedTab = .game
        activeSelectionSheet = selection
    }

    private var availableDailyReward: DailyLoginRewardState? {
        PlayerInventoryStore.dailyLoginGift(
            from: dailyLoginRewards,
            in: modelContext
        )
    }

    private var storyArchiveChapters: [GlobeEventChapter] {
        gameState.eventChapters.filter { !isEventChapter($0) }
    }

    private var eventArchiveChapters: [GlobeEventChapter] {
        gameState.eventChapters.filter { isEventChapter($0) }
    }

    private var completedBattleIDs: Set<String> {
        Set(completedBattles.map(\.battleID))
    }

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    private var ascendedXP: Int {
        accountProgress.first?.xp ?? 0
    }

    private var battleResourceStatus: BattleResourceStatus {
        PlayerInventoryStore.dailyBattleFarmStatus(
            in: modelContext,
            now: resourceRefreshDate
        )
    }

    private var battleResourceBar: some View {
        HStack(spacing: 8) {
            resourceChip(
                title: "Energie",
                value:
                    "\(battleResourceStatus.energy)/\(battleResourceStatus.energyMaximum)",
                systemName: "bolt.fill",
                accent: .orange
            )
            resourceChip(
                title: "Coin Limit",
                value: "\(battleResourceStatus.remainingCoins)",
                assetName: "icon_coins",
                accent: .yellow
            )
            resourceChip(
                title: "Crystal Limit",
                value: "\(battleResourceStatus.remainingCrystals)",
                assetName: "icon_crystals",
                accent: .cyan
            )
        }
    }

    private func resourceChip(
        title: String,
        value: String,
        assetName: String? = nil,
        systemName: String = "circle.fill",
        accent: Color
    ) -> some View {
        HStack(spacing: 7) {
            if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.68))
                Text(value)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.46), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var activePreviewChapter: GlobeEventChapter? {
        if let chapter = gameState.activeEventChapter,
            isChapterUnlocked(chapter)
        {
            return chapter
        }
        return gameState.eventChapters.first { isChapterUnlocked($0) }
    }

    private func activePreviewPoint(for chapter: GlobeEventChapter)
        -> GlobeEventPoint?
    {
        if chapter.id == gameState.activeEventChapterID,
            let point = gameState.activeEventPoint
        {
            return point
        }
        return chapter.points.first
    }

    private func isChapterUnlocked(_ chapter: GlobeEventChapter) -> Bool {
        guard ascendedLevel >= (chapter.minAscendedLevel ?? 1) else {
            return false
        }
        guard !isEventChapter(chapter) else { return true }

        guard
            let index = gameState.eventChapters.firstIndex(where: {
                $0.id == chapter.id
            })
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
        battleResourceMessage = ""
        gameState.selectBattle(battle)
        selectedEnemy = battle.primaryEnemy
        currentStory = battle.story

        withAnimation(.easeInOut(duration: 0.25)) {
            showStory = !battle.story.isEmpty
            showPopup = battle.story.isEmpty
        }
    }

    private func startSelectedBattleIfPossible() {
        let now = Date()
        guard
            PlayerInventoryStore.consumeBattleEnergyForStart(
                in: modelContext,
                now: now
            )
        else {
            resourceRefreshDate = now
            battleResourceMessage =
                "Nicht genug Energie. +\(battleResourceStatus.energyRegenerationPerMinute) pro Minute."
            return
        }
        resourceRefreshDate = now
        battleResourceMessage = ""
        if let selectedEnemy {
            onStartBattle(selectedEnemy)
        }
    }

    private func claimDailyGiftFromMenu() {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimDailyLoginGift(
            from: dailyLoginRewards,
            in: modelContext
        )
        showDailyLogin = false
    }

    private func claimGiftFromMenu(_ gift: GiftBoxDefinition) {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimGiftBox(gift, in: modelContext)
    }
}

#Preview {
    GameView(onStartBattle: { _ in })
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
