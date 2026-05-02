//
//  RootView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var musicManager: MusicManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var remoteContent: RemoteContentManager
    @Environment(\.modelContext) private var modelContext

    private enum Screen {
        case start
        case introVideo
        case tutorialBattle
        case tutorialArchive
        case createClass
        case game
        case battle
    }

    private enum TutorialLaunchSource {
        case initial
        case archive
    }

    @State private var currentScreen: Screen = .start
    @State private var activeEnemy: CharacterStats?
    @State private var pendingDailyReward: DailyLoginRewardState?
    @State private var activeTutorial: GameTutorialDefinition?
    @State private var activeIntroIndex = 0
    @State private var tutorialLaunchSource: TutorialLaunchSource = .initial
    @State private var showStartupOptions = false
    @State private var hasStartedStartupFlow = false
    @State private var showStartTransitionOverlay = false
    @State private var startTransitionTask: Task<Void, Never>?
    @State private var gameEntryLoadingStatusText =
        "Start-Assets werden geladen"

    private let introFlowKey = "hasCompletedIntroFlow"

    private var dailyLoginRewards: [DailyLoginRewardDefinition] {
        loadDailyLoginRewardDefinitions()
    }

    private var introVideos: [IntroVideoDefinition] {
        loadIntroVideoDefinitions()
    }

    private var tutorials: [GameTutorialDefinition] {
        loadTutorialDefinitions()
    }

    private var showsStartupLoadingView: Bool {
        !remoteContent.hasCompletedInitialRefresh
            || remoteContent.isPreparingStartupPlan
    }

    private var showsActiveRemoteLoadingOverlay: Bool {
        remoteContent.isPreparingStartupPlan || remoteContent.isRefreshing
    }

    private var showsGameEntryLoadingOverlay: Bool {
        showStartTransitionOverlay && !showsActiveRemoteLoadingOverlay
    }

    private var startupLoadingBackground: String {
        if let themeBackground = theme.selectedTheme?.background,
            !themeBackground.isEmpty
        {
            return themeBackground
        }

        return loadingImages.first ?? "theme_epic"
    }

    private var gameEntryLoadingBackground: String {
        startupLoadingBackground
    }

    var body: some View {
        ZStack {
            if remoteContent.hasCompletedInitialRefresh {
                contentLayer
            } else {
                Color.black.ignoresSafeArea()
            }

            if showsStartupLoadingView && !showsActiveRemoteLoadingOverlay {
                RemoteLoadingView(
                    plan: remoteContent.startupPlan,
                    isPreparingPlan: remoteContent.isPreparingStartupPlan,
                    isStarting: remoteContent.isRefreshing,
                    progress: remoteContent.isRefreshing
                        ? remoteContent.refreshProgress : 0.08,
                    statusText: remoteContent.statusText,
                    requiresMandatoryUpdate: remoteContent
                        .requiresMandatoryUpdate,
                    failureMessage: remoteContent.startupFailureMessage,
                    requiresRetry: remoteContent.startupReloadRequired,
                    isConnected: networkMonitor.isConnected,
                    showOptions: $showStartupOptions,
                    onPreloadAll: {
                        startRemoteBootstrap(mode: .fullPreload)
                    },
                    onPlayWithoutPreload: {
                        startRemoteBootstrap(mode: .bootstrap)
                    },
                    onRetry: {
                        retryStartupLoading()
                    }
                )
                .environmentObject(theme)
                .zIndex(300)
            }

            if showsActiveRemoteLoadingOverlay {
                LoadingOverlayView(
                    title: "Realm Sync",
                    subtitle:
                        "Remote content, battle data und assets werden geladen.",
                    progress: remoteContent.refreshProgress,
                    statusText: remoteContent.statusText
                )
                .environmentObject(theme)
                .zIndex(320)
            }

            if showsGameEntryLoadingOverlay {
                LoadingOverlayView(
                    title: "Entering Ascended Realms",
                    subtitle: "Die Welt wird fuer deinen Start vorbereitet.",
                    progress: nil,
                    statusText: gameEntryLoadingStatusText
                )
                .environmentObject(theme)
                .transition(.opacity)
                .zIndex(310)
            }

            if remoteContent.hasCompletedInitialRefresh
                && remoteContent.isBackgroundPreloading
            {
                VStack {
                    BackgroundPreloadIndicatorView(
                        progress: remoteContent.backgroundPreloadProgress,
                        statusText: remoteContent.backgroundStatusText
                    )

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(180)
            }

            if currentScreen == .game, let pendingDailyReward {
                DailyLoginPopupView(
                    rewardState: pendingDailyReward,
                    onClaim: claimDailyGift
                )
                .environmentObject(gameState)
                .environmentObject(theme)
                .zIndex(200)
            }

            if !networkMonitor.isConnected {
                offlineOverlay
                    .zIndex(500)
            }
        }
        .animation(.smooth(duration: 0.45), value: currentScreenID)
        .onAppear {
            guard !hasStartedStartupFlow else { return }
            hasStartedStartupFlow = true
            Task {
                await remoteContent.prepareStartupPlanIfNeeded()
            }
        }
        .onDisappear {
            startTransitionTask?.cancel()
        }
    }

    private var offlineOverlay: some View {
        ZStack {
            Color.black.opacity(0.76)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.yellow)

                Text("Internetverbindung benötigt")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)

                Text(
                    remoteContent.startupReloadRequired
                        ? "Die Verbindung ist während des Ladens abgebrochen. Das Spiel bleibt gesperrt, bis du nach Wiederverbindung den Download neu startest."
                        : "Slayken Ascended Realms kann aktuell nur mit aktiver Internetverbindung gespielt werden. Bitte verbinde dich mit dem Internet."
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .background(Color.black.opacity(0.52))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    private var currentScreenID: String {
        switch currentScreen {
        case .start:
            return "start"
        case .introVideo:
            return "introVideo"
        case .tutorialBattle:
            return "tutorialBattle"
        case .tutorialArchive:
            return "tutorialArchive"
        case .createClass:
            return "createClass"
        case .game:
            return "game"
        case .battle:
            return "battle"
        }
    }

    private var loadingImages: [String] {
        let assets = gameState.backgrounds.map(\.image)
        if assets.isEmpty {
            return [
                "theme_epic", "theme_fire", "bg_sar", "bg_map", "bg_country",
                "bg_arena", "bg_fire",
                "bg_ice", "bg_void",
            ]
        }

        var seen = Set<String>()
        return assets.filter { seen.insert($0).inserted }
    }

    @ViewBuilder
    private var contentLayer: some View {
        switch currentScreen {
        case .start:
            StartView {
                startGameFlow()
            }

        case .introVideo:
            if let activeIntroVideo {
                IntroVideoView(
                    introVideo: activeIntroVideo,
                    onFinish: {
                        playNextIntroOrBeginTutorial()
                    }
                )
                .id(activeIntroVideo.id)
            }

        case .tutorialBattle:
            if let activeTutorial,
                let primaryEnemy = activeTutorial.primaryEnemy
            {
                BattleView(
                    player: activeTutorial.player,
                    enemy: primaryEnemy,
                    enemiesOverride: activeTutorial.allEnemies,
                    onExit: {
                        handleTutorialExit()
                    },
                    tutorialConfig: .init(
                        title: activeTutorial.title,
                        objective: activeTutorial.objective,
                        retreatEnemyIndex: activeTutorial.retreatEnemyIndex,
                        enemyRetreatThreshold: activeTutorial
                            .enemyRetreatThreshold,
                        onEnemyRetreat: completeTutorialBattle,
                        onBattleComplete: completeTutorialBattle
                    )
                )
            }

        case .tutorialArchive:
            TutorialArchiveView(
                tutorials: tutorials,
                onClose: {
                    resetToStart()
                },
                onReplay: { tutorial in
                    replayTutorial(tutorial)
                }
            )
            .environmentObject(theme)

        case .createClass:
            CreateClassView(
                onClose: {
                    transition(to: .game)
                },
                onComplete: {
                    completeClassCreation(with: $0)
                }
            )
            .environmentObject(gameState)
            .environmentObject(theme)

        case .game:
            GameView(
                onResetGame: {
                    resetGameProgress()
                },
                onOpenTutorialArchive: {
                    openTutorialArchive(fromGame: true)
                },
                onOpenCreateClass: {
                    refreshDailyGift()
                }
            ) { enemy in
                transition(to: .battle, enemy: enemy)
            }
        case .battle:
            if let activeEnemy {
                BattleView(
                    player: gameState.battlePlayer,
                    enemy: activeEnemy,
                    onExit: {
                        gameState.clearBattleSelection()
                        transition(to: .game)
                    }
                )
            }
        }
    }

    private func transition(to screen: Screen, enemy: CharacterStats? = nil) {
        withAnimation(.smooth(duration: 0.35)) {
            activeEnemy = enemy
            currentScreen = screen
            if screen != .battle {
                activeEnemy = nil
            }
        }
    }

    private func startRemoteBootstrap(mode: RemoteContentRefreshMode) {
        guard !remoteContent.isRefreshing else { return }

        Task {
            let didRefreshSucceed = await remoteContent.refreshContentIfNeeded(
                mode: mode
            )
            guard didRefreshSucceed else { return }

            gameState.reloadContent()
            theme.loadThemes()
            theme.loadSelected()
            musicManager.reloadTracks()
            musicManager.startPlaybackIfNeeded()
            refreshDailyGift()

            if mode == .bootstrap {
                remoteContent.startBackgroundPreloadIfNeeded()
            }
        }
    }

    private func retryStartupLoading() {
        guard !remoteContent.isRefreshing else { return }

        Task {
            await remoteContent.retryStartupRefreshPreparation()
        }
    }

    private func resetToStart() {
        gameState.clearBattleSelection()
        activeEnemy = nil
        activeIntroIndex = 0
        activeTutorial = nil
        refreshDailyGift()

        withAnimation(.smooth(duration: 0.35)) {
            currentScreen = .start
        }
    }

    private func refreshDailyGift() {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        pendingDailyReward = PlayerInventoryStore.dailyLoginGift(
            from: dailyLoginRewards,
            in: modelContext
        )
    }

    private func claimDailyGift() {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimDailyLoginGift(
            from: dailyLoginRewards,
            in: modelContext
        )
        pendingDailyReward = nil
    }

    private var hasCompletedIntroFlow: Bool {
        UserDefaults.standard.bool(forKey: introFlowKey)
    }

    private var introTutorial: GameTutorialDefinition? {
        tutorials.first
    }

    private var activeIntroVideo: IntroVideoDefinition? {
        guard openingIntroVideos.indices.contains(activeIntroIndex) else {
            return nil
        }
        return openingIntroVideos[activeIntroIndex]
    }

    private var openingIntroVideos: [IntroVideoDefinition] {
        introVideos
            .filter { ($0.flow ?? "opening") == "opening" }
            .sorted {
                ($0.order ?? .max, $0.id) < ($1.order ?? .max, $1.id)
            }
    }

    private func startGameFlow() {
        if hasCompletedIntroFlow || introTutorial == nil {
            beginGameEntryTransition()
        } else if !openingIntroVideos.isEmpty {
            activeIntroIndex = 0
            tutorialLaunchSource = .initial
            transition(to: .introVideo)
        } else {
            beginTutorialBattle()
        }
    }

    private func beginGameEntryTransition() {
        guard !showStartTransitionOverlay else { return }

        startTransitionTask?.cancel()
        gameEntryLoadingStatusText = "Start-Assets werden geladen"
        withAnimation(.easeInOut(duration: 0.2)) {
            showStartTransitionOverlay = true
        }

        startTransitionTask = Task {
            await preloadGameEntryAssets()
            if Task.isCancelled { return }

            await MainActor.run {
                transition(to: .game)
            }

            try? await Task.sleep(for: .milliseconds(150))
            if Task.isCancelled { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showStartTransitionOverlay = false
                }
                startTransitionTask = nil
            }
        }
    }

    private func preloadGameEntryAssets() async {
        await preloadImageAsset(
            named: gameEntryLoadingBackground,
            status: "Lade Start-Hintergrund"
        )
        await preloadImageAsset(
            named: gameState.activeSkyboxTexture,
            status: "Lade Skybox"
        )
        await preloadImageAsset(
            named: gameState.activeGroundTexture,
            status: "Lade Boden-Textur"
        )

        if let playerTexture = gameState.player.texture, !playerTexture.isEmpty
        {
            await preloadImageAsset(
                named: playerTexture,
                status: "Lade Charakter-Textur"
            )
        }

        await preloadModelAsset(
            named: gameState.player.model,
            status: "Lade Charakter-Modell"
        )
    }

    private func preloadImageAsset(named assetName: String, status: String)
        async
    {
        let trimmedName = assetName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        while !Task.isCancelled {
            await MainActor.run {
                gameEntryLoadingStatusText = status
            }

            if RemoteContentManager.hasCachedOrBundledImage(named: trimmedName)
            {
                return
            }

            await remoteContent.downloadAssetIfNeeded(named: trimmedName)

            if RemoteContentManager.hasCachedOrBundledImage(named: trimmedName)
            {
                return
            }

            await MainActor.run {
                gameEntryLoadingStatusText = "\(status) erneut"
            }
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    private func preloadModelAsset(named assetName: String, status: String)
        async
    {
        let trimmedName = assetName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        while !Task.isCancelled {
            await MainActor.run {
                gameEntryLoadingStatusText = status
            }

            if RemoteContentManager.cachedAssetURL(
                named: trimmedName,
                preferredExtensions: ["usdz", "scn"]
            ) != nil {
                return
            }

            await remoteContent.downloadAssetIfNeeded(named: trimmedName)

            if RemoteContentManager.cachedAssetURL(
                named: trimmedName,
                preferredExtensions: ["usdz", "scn"]
            ) != nil {
                return
            }

            await MainActor.run {
                gameEntryLoadingStatusText = "\(status) erneut"
            }
            try? await Task.sleep(for: .milliseconds(400))
        }
    }

    private func completeTutorialBattle() {
        if tutorialLaunchSource == .archive || hasCompletedIntroFlow {
            transition(to: .tutorialArchive)
        } else {
            transition(to: .createClass)
        }
    }

    private func completeClassCreation(with character: CharacterStats) {
        gameState.saveCharacter(character)
        UserDefaults.standard.set(true, forKey: introFlowKey)
        transition(to: .game)
    }

    private func openTutorialArchive(fromGame: Bool = false) {
        tutorialLaunchSource = .archive
        activeTutorial = nil
        transition(to: .tutorialArchive)
        if fromGame {
            gameState.clearBattleSelection()
        }
    }

    private func replayTutorial(_ tutorial: GameTutorialDefinition) {
        activeTutorial = tutorial
        tutorialLaunchSource = .archive
        transition(to: .tutorialBattle)
    }

    private func beginTutorialBattle() {
        activeIntroIndex = 0
        activeTutorial = introTutorial
        tutorialLaunchSource = .initial
        transition(to: .tutorialBattle)
    }

    private func playNextIntroOrBeginTutorial() {
        let nextIndex = activeIntroIndex + 1
        if openingIntroVideos.indices.contains(nextIndex) {
            activeIntroIndex = nextIndex
        } else {
            beginTutorialBattle()
        }
    }

    private func handleTutorialExit() {
        if tutorialLaunchSource == .archive || hasCompletedIntroFlow {
            activeTutorial = nil
            transition(to: .game)
        } else {
            resetToStart()
        }
    }

    private func resetGameProgress() {
        UserDefaults.standard.removeObject(forKey: introFlowKey)
        resetToStart()
    }
}

#Preview {
    RootView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
        .environmentObject(MusicManager())
        .environmentObject(NetworkMonitor())
        .environmentObject(RemoteContentManager.shared)
}
