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
    @EnvironmentObject var multiplayerManager: MultiplayerManager
    @EnvironmentObject var remoteContent: RemoteContentManager
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
    @State private var activeLoginCampaignID: String?
    @State private var selectedTab: GameTab = .game
    @State private var resourceRefreshDate = Date()
    @State private var battleResourceMessage = ""
    @State private var pendingBattleStartTask: Task<Void, Never>?
    @State private var pendingBattleArrivalID: String?
    @State private var showMultiplayerLobby = false
    @State private var showBattleStartTransition = false
    @State private var renderGameScene = false

    private enum ModalTabDestination {
        case character
        case summon
        case shop
        case events
    }

    private var gifts: [GiftBoxDefinition] {
        loadGiftBoxDefinitions()
    }

    private var loginCampaigns: [LoginRewardCampaign] {
        loadLoginRewardCampaigns()
    }

    private var quests: [QuestDefinition] {
        loadQuestDefinitions()
    }

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

                if renderGameScene {
                    GameSceneView(
                        player: gameState.player,
                        joystickVector: joystickVector,
                        autoMoveTarget: autoMoveTarget,
                        groundTexture: gameState.activeGroundTexture,
                        skyboxTexture: gameState.activeSkyboxTexture,
                        onAutoMoveFinished: {
                            handleAutoMoveFinished()
                        }
                    )
                    .id(
                        "\(gameState.player.model)-\(gameState.player.texture ?? "default")"
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                } else {
                    gameScenePlaceholder
                        .ignoresSafeArea()
                }

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

                if showBattleStartTransition {
                    battleStartTransitionOverlay
                        .transition(.opacity)
                        .zIndex(60)
                }

                if shouldShowMapPreview {
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
                        playerName: gameState.player.name,
                        playerPreviewImage: gameState.player.image,
                        currencies: gameState.currencies,
                        ascendedLevel: ascendedLevel,
                        ascendedXP: ascendedXP,
                        energy: battleResourceStatus.energy,
                        maxEnergy: battleResourceStatus.energyMaximum,
                        horizontalPadding: horizontalOverlayPadding,
                        onOpenShop: {
                            showShop = true
                        },
                        onOpenQuests: {
                            showQuests = true
                        },
                        onOpenCoop: {
                            multiplayerManager.ensureLocalLobbyState()
                            showMultiplayerLobby = true
                        }
                    )
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
                    GameFooterView(
                        selectedTab: $selectedTab,
                        onSelectTab: openFooterDestination
                    )
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
                        activeLoginCampaignID = preferredLoginCampaignID
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
            .overlay(alignment: .bottomTrailing) {
                if remoteContent.isBackgroundPreloading {
                    BackgroundPreloadIndicatorView(
                        progress: remoteContent.backgroundPreloadProgress,
                        statusText: remoteContent.backgroundStatusText
                    )
                    .padding(.trailing, 22)
                    .padding(.bottom, 118)
                    .transition(.scale.combined(with: .opacity))
                }
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
            .fullScreenCover(isPresented: $showMultiplayerLobby) {
                CoopRaidFlowView {
                    multiplayerManager.leaveLobby()
                    showMultiplayerLobby = false
                }
                .environmentObject(multiplayerManager)
                .environmentObject(theme)
                .environmentObject(remoteContent)
            }
            .fullScreenCover(
                isPresented: Binding(
                    get: { multiplayerManager.activeRaid != nil },
                    set: { isPresented in
                        if !isPresented {
                            multiplayerManager.endRaid()
                        }
                    }
                )
            ) {
                BattleView(
                    player: gameState.battlePlayer,
                    enemy: multiplayerManager.activeRaid?.battleConfiguration
                        .boss ?? gameState.battlePlayer,
                    enemiesOverride: multiplayerManager.activeRaid.map {
                        [$0.battleConfiguration.boss]
                    },
                    onExit: {
                        multiplayerManager.endRaid()
                    },
                    tutorialConfig: nil,
                    raidConfiguration: multiplayerManager.activeRaid?
                        .battleConfiguration,
                    onRaidBossHPChanged: nil,
                    onRaidCombatLog: nil,
                    onRaidFinished: { victory in
                        multiplayerManager.setRaidOutcome(victory: victory)
                    }
                )
                .environmentObject(gameState)
                .environmentObject(theme)
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
                    campaigns: loginCampaigns,
                    selectedCampaignID: activeLoginCampaign?.id,
                    campaignTitle: activeLoginCampaign?.title ?? "Daily Login",
                    campaignSubtitle: activeLoginCampaign?.subtitle
                        ?? "Login-Belohnungen",
                    rewards: activeLoginCampaign?.rewards ?? [],
                    currencies: gameState.currencies,
                    availableReward: activeAvailableLoginReward,
                    onClaim: claimDailyGiftFromMenu,
                    onSelectCampaign: { campaignID in
                        activeLoginCampaignID = campaignID
                    },
                    onClose: {
                        showDailyLogin = false
                    }
                )
                .environmentObject(gameState)
                .environmentObject(theme)
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
                    resetTabAfterModalDismiss(.character)
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
            .fullScreenCover(
                isPresented: $showShop,
                onDismiss: {
                    resetTabAfterModalDismiss(.shop)
                }
            ) {
                ShopView(onClose: {
                    showShop = false
                    selectedTab = .game
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
                    resetTabAfterModalDismiss(.summon)
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
                    resetTabAfterModalDismiss(.events)
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
                        moveToBattleAndStart(battle)
                    }
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer()

                        GameFooterView(
                            selectedTab: $selectedTab,
                            onSelectTab: openFooterDestination
                        )
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
                            activeLoginCampaignID = preferredLoginCampaignID
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
                openFooterDestination(newTab)
            }
            .task {
                await Task.yield()
                withAnimation(.easeInOut(duration: 0.18)) {
                    renderGameScene = true
                }

                while !Task.isCancelled {
                    resourceRefreshDate = .now
                    try? await Task.sleep(for: .seconds(20))
                }
            }
            .onDisappear {
                pendingBattleStartTask?.cancel()
                pendingBattleStartTask = nil
                showBattleStartTransition = false
                renderGameScene = false
            }
            .onChange(of: multiplayerManager.lobbyState) { _, newValue in
                gameState.updateRaidLobby(newValue)
            }
            .onChange(of: multiplayerManager.activeRaid) { _, newValue in
                if newValue != nil {
                    showMultiplayerLobby = false
                }
                gameState.updateRaidSession(newValue)
            }
        }
    }

    private var shouldShowMapPreview: Bool {
        !showStory
            && !showPopup
            && !showCharacter
            && !showSummon
            && !showShop
            && !showGlobeEvents
    }

    private func resetTabAfterModalDismiss(_ destination: ModalTabDestination) {
        switch destination {
        case .character:
            if selectedTab == .character {
                selectedTab = .game
            }
        case .summon:
            if selectedTab == .summon {
                selectedTab = .game
            }
        case .shop:
            if selectedTab == .shop {
                selectedTab = .game
            }
        case .events:
            if selectedTab == .events {
                selectedTab = .game
            }
        }
    }

    private func closeGlobeAndOpen(_ selection: ActiveSelectionSheet) {
        showGlobeEvents = false
        selectedTab = .game
        activeSelectionSheet = selection
    }

    private var availableDailyReward: DailyLoginRewardState? {
        loginCampaignReward(
            for: loginCampaigns.first { $0.id == "daily_login" }
        )
    }

    private var activeLoginCampaign: LoginRewardCampaign? {
        if let activeLoginCampaignID,
            let campaign = loginCampaigns.first(where: {
                $0.id == activeLoginCampaignID
            })
        {
            return campaign
        }

        return loginCampaigns.first
    }

    private var activeAvailableLoginReward: DailyLoginRewardState? {
        loginCampaignReward(for: activeLoginCampaign)
    }

    private var preferredLoginCampaignID: String? {
        nextAvailableLoginCampaign()?.id ?? loginCampaigns.first?.id
    }

    private var storyArchiveChapters: [GlobeEventChapter] {
        gameState.eventChapters.filter { !$0.isEventChapter }
    }

    private var eventArchiveChapters: [GlobeEventChapter] {
        gameState.eventChapters.filter(\.isEventChapter)
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
            coopRaidButton
        }
    }

    private var coopRaidButton: some View {
        Button {
            multiplayerManager.ensureLocalLobbyState()
            showMultiplayerLobby = true
        } label: {
            Label(
                multiplayerManager.activeRaid == nil
                    ? "Coop" : "Raid aktiv",
                systemImage: multiplayerManager.activeRaid == nil
                    ? "person.3.sequence.fill"
                    : "flame.fill"
            )
            .font(.system(size: 12, weight: .black))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.38), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func resourceChip(
        title: String,
        value: String,
        assetName: String? = nil,
        systemName: String = "circle.fill",
        accent: Color
    ) -> some View {
        HStack(spacing: 7) {
            if let assetName {
                RemoteAssetImage(assetName, contentMode: .fit) {
                    Image(systemName: systemName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(accent)
                }
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
            chapter.isUnlocked(
                in: gameState.eventChapters,
                completedBattleIDs: completedBattleIDs,
                ascendedLevel: ascendedLevel
            )
        {
            return chapter
        }
        return gameState.eventChapters.first { chapter in
            chapter.isUnlocked(
                in: gameState.eventChapters,
                completedBattleIDs: completedBattleIDs,
                ascendedLevel: ascendedLevel
            )
        }
    }

    private var gameScenePlaceholder: some View {
        ZStack {
            RemoteAssetImage(gameState.activeSkyboxTexture) {
                Color.black
            }
            LinearGradient(
                colors: [
                    Color.black.opacity(0.26),
                    Color.black.opacity(0.58),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var battleStartTransitionOverlay: some View {
        ZStack {
            Color.black.opacity(0.86)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.08)

                Text("Battle startet")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)

                Text(gameState.selectedBattle?.name ?? "Risskampf")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
    }

    private func activePreviewPoint(for chapter: GlobeEventChapter)
        -> GlobeEventPoint?
    {
        if chapter.id == gameState.activeEventChapterID,
            let point = gameState.activeEventPoint,
            point.visibleBattles(
                completedBattleIDs: completedBattleIDs,
                revealsSequentially: true
            )
            .contains(where: {
                $0.id == gameState.activeEventBattleID
                    || !completedBattleIDs.contains($0.id)
            })
        {
            return point
        }

        return chapter.nextUnlockedPoint(completedBattleIDs: completedBattleIDs)
            ?? chapter.points.first
    }

    private func moveToBattleAndStart(_ battle: GlobeBattle) {
        pendingBattleStartTask?.cancel()
        pendingBattleStartTask = nil
        pendingBattleArrivalID = battle.id
        autoMoveTarget = sceneTarget(for: battle.node)
        gameState.selectBattle(battle)
    }

    private func handleAutoMoveFinished() {
        guard
            let pendingBattleArrivalID,
            let battle = gameState.selectedBattle,
            battle.id == pendingBattleArrivalID
        else {
            autoMoveTarget = nil
            self.pendingBattleArrivalID = nil
            return
        }

        autoMoveTarget = nil
        self.pendingBattleArrivalID = nil
        presentBattleIntro(battle)
    }

    private func openFooterDestination(_ tab: GameTab) {
        switch tab {
        case .events:
            showGlobeEvents = true
        case .character:
            showCharacter = true
        case .summon:
            showSummon = true
        case .shop:
            showShop = true
        default:
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

    private func sceneTarget(for node: EventMapNodePosition) -> SIMD2<Float> {
        SIMD2<Float>(
            Float(node.x - 0.5) * 70,
            Float(0.5 - node.y) * 70
        )
    }

    private func presentBattleIntro(_ battle: GlobeBattle) {
        battleResourceMessage = ""
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

        guard let selectedEnemy else { return }

        pendingBattleStartTask?.cancel()
        pendingBattleStartTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.16)) {
                showPopup = false
                showStory = false
                showBattleStartTransition = true
            }

            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch {
                withAnimation(.easeInOut(duration: 0.12)) {
                    showBattleStartTransition = false
                }
                return
            }

            onStartBattle(selectedEnemy)
        }
    }

    private func claimDailyGiftFromMenu() {
        guard let campaign = activeLoginCampaign else {
            showDailyLogin = false
            return
        }

        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimDailyLoginGift(
            from: campaign.rewards,
            progressID: campaign.id,
            in: modelContext
        )
        if let nextCampaign = nextAvailableLoginCampaign() {
            activeLoginCampaignID = nextCampaign.id
        } else {
            showDailyLogin = false
        }
    }

    private func loginCampaignReward(for campaign: LoginRewardCampaign?)
        -> DailyLoginRewardState?
    {
        guard let campaign, !campaign.rewards.isEmpty else { return nil }
        return PlayerInventoryStore.dailyLoginGift(
            from: campaign.rewards,
            progressID: campaign.id,
            in: modelContext
        )
    }

    private func nextAvailableLoginCampaign() -> LoginRewardCampaign? {
        loginCampaigns.first { campaign in
            loginCampaignReward(for: campaign) != nil
        }
    }

    private func claimGiftFromMenu(_ gift: GiftBoxDefinition) {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimGiftBox(gift, in: modelContext)
    }
}
