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
    @EnvironmentObject var deepLinkRouter: AppDeepLinkRouter
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

    private struct PendingLoginPopup: Equatable {
        let campaign: LoginRewardCampaign
        let rewardState: DailyLoginRewardState
    }

    @State private var currentScreen: Screen = .start
    @State private var activeEnemy: CharacterStats?
    @State private var pendingLoginPopup: PendingLoginPopup?
    @State private var activeTutorial: GameTutorialDefinition?
    @State private var activeIntroIndex = 0
    @State private var tutorialLaunchSource: TutorialLaunchSource = .initial
    @State private var showStartupOptions = false
    @State private var hasStartedStartupFlow = false
    @State private var showStartTransitionOverlay = false
    @State private var startTransitionTask: Task<Void, Never>?
    @State private var runtimeUpdateCheckTask: Task<Void, Never>?
    @State private var gameEntryLoadingStatusText =
        "Start-Assets werden geladen"

    private let introFlowKey = "hasCompletedIntroFlow"
    private let runtimeUpdateCheckInterval: Duration = .seconds(60)
    private let gameEntryPreloadTimeoutNanoseconds: UInt64 = 6_000_000_000

    private var introVideos: [IntroVideoDefinition] {
        loadIntroVideoDefinitions()
    }

    private var tutorials: [GameTutorialDefinition] {
        loadTutorialDefinitions()
    }

    private var showsStartupLoadingView: Bool {
        !remoteContent.hasCompletedInitialRefresh
            || remoteContent.isPreparingStartupPlan
            || remoteContent.isMaintenanceActive
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
                    .transition(.opacity)
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
                    maintenance: remoteContent.activeMaintenance,
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

            if currentScreen == .game, let pendingLoginPopup {
                DailyLoginPopupView(
                    campaignTitle: pendingLoginPopup.campaign.title,
                    campaignSubtitle: pendingLoginPopup.campaign.subtitle,
                    campaignEndsAt: pendingLoginPopup.campaign.endsAt,
                    rewards: pendingLoginPopup.campaign.rewards,
                    rewardState: pendingLoginPopup.rewardState,
                    onClaim: claimLoginGift
                )
                .environmentObject(gameState)
                .environmentObject(theme)
                .zIndex(200)
            }

            if !networkMonitor.isConnected {
                offlineOverlay
                    .zIndex(500)
            }

            if remoteContent.hasRuntimeRequiredUpdate
                && !remoteContent.isRefreshing
            {
                runtimeUpdateOverlay
                    .zIndex(520)
            }
        }
        .animation(.smooth(duration: 0.45), value: currentScreenID)
        .animation(
            .easeInOut(duration: 0.28),
            value: remoteContent.hasCompletedInitialRefresh
        )
        .onAppear {
            guard !hasStartedStartupFlow else { return }
            hasStartedStartupFlow = true
            Task {
                await remoteContent.prepareStartupPlanIfNeeded()
            }
            startRuntimeUpdateChecks()
        }
        .onDisappear {
            startTransitionTask?.cancel()
            runtimeUpdateCheckTask?.cancel()
        }
        .onChange(of: deepLinkRouter.pendingDestination) { _, _ in
            routePendingDeepLinkIfPossible()
        }
        .onChange(of: remoteContent.hasCompletedInitialRefresh) { _, _ in
            routePendingDeepLinkIfPossible()
        }
    }

    private var runtimeUpdateOverlay: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(.blue)

                Text("Update verfügbar")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)

                Text(
                    "Ein neues Inhalts-Update ist verfügbar. Lade das Update herunter, um weiterzuspielen."
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineSpacing(3)

                if let plan = remoteContent.startupPlan {
                    HStack(spacing: 10) {
                        runtimeUpdatePill(
                            title: "Daten",
                            value: "\(plan.pendingResourceCount)"
                        )
                        runtimeUpdatePill(
                            title: "Assets",
                            value: "\(plan.pendingAssetCount)"
                        )
                        runtimeUpdatePill(
                            title: "Größe",
                            value: plan.formattedEstimatedSize
                        )
                    }
                }

                Button {
                    startRemoteBootstrap(mode: .fullPreload)
                } label: {
                    Text("Update herunterladen")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.12, green: 0.42, blue: 1.0))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .background(Color.black.opacity(0.58))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    private func runtimeUpdatePill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        let assets = gameState.eventChapters.map(\.mapTexture)
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
                    refreshLoginPopups()
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
        guard !remoteContent.hasRuntimeRequiredUpdate else { return }
        withAnimation(.smooth(duration: 0.35)) {
            activeEnemy = enemy
            currentScreen = screen
            if screen != .battle {
                activeEnemy = nil
            }
        }
    }

    private func startRuntimeUpdateChecks() {
        runtimeUpdateCheckTask?.cancel()
        runtimeUpdateCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: runtimeUpdateCheckInterval)
                if Task.isCancelled { break }

                let isConnected = await MainActor.run {
                    networkMonitor.isConnected
                }
                guard isConnected else { continue }

                await remoteContent.checkForRuntimeUpdateIfNeeded()
            }
        }
    }

    private func startRemoteBootstrap(mode: RemoteContentRefreshMode) {
        guard !remoteContent.isRefreshing else { return }

        Task {
            guard networkMonitor.isConnected else {
                remoteContent.failStartupRetryBecauseOffline()
                return
            }

            let didRefreshSucceed = await remoteContent.refreshContentIfNeeded(
                mode: mode
            )
            guard didRefreshSucceed else { return }

            completeRemoteRefresh(mode: mode)
        }
    }

    private func retryStartupLoading() {
        guard !remoteContent.isRefreshing else { return }

        Task {
            await remoteContent.retryStartupRefreshPreparation()
            guard networkMonitor.isConnected else {
                remoteContent.failStartupRetryBecauseOffline()
                return
            }

            let didRefreshSucceed = await remoteContent.refreshContentIfNeeded(
                mode: .fullPreload
            )
            guard didRefreshSucceed else { return }

            completeRemoteRefresh(mode: .fullPreload)
        }
    }

    private func completeRemoteRefresh(mode: RemoteContentRefreshMode) {
        gameState.reloadContent()
        theme.loadThemes()
        theme.loadSelected()
        musicManager.reloadTracks()
        musicManager.startPlaybackIfNeeded()
        refreshLoginPopups()
        routePendingDeepLinkIfPossible()

        if mode == .bootstrap {
            remoteContent.startBackgroundPreloadIfNeeded()
        }
    }

    private func routePendingDeepLinkIfPossible() {
        guard deepLinkRouter.pendingDestination != nil else { return }
        guard remoteContent.hasCompletedInitialRefresh else { return }
        guard !remoteContent.hasRuntimeRequiredUpdate else { return }

        if currentScreen != .game {
            startTransitionTask?.cancel()
            startTransitionTask = nil
            showStartTransitionOverlay = false
            activeEnemy = nil
            transition(to: .game)
        }
    }

    private func resetToStart() {
        gameState.clearBattleSelection()
        activeEnemy = nil
        activeIntroIndex = 0
        activeTutorial = nil
        refreshLoginPopups()

        withAnimation(.smooth(duration: 0.35)) {
            currentScreen = .start
        }
    }

    private func refreshLoginPopups() {
        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        pendingLoginPopup = nextPendingLoginPopup()
    }

    private func claimLoginGift() {
        guard let pendingLoginPopup else { return }

        PlayerInventoryStore.ensureBalances(
            for: gameState.currencies,
            in: modelContext
        )
        _ = PlayerInventoryStore.claimDailyLoginGift(
            from: pendingLoginPopup.campaign.rewards,
            progressID: pendingLoginPopup.campaign.id,
            in: modelContext
        )
        self.pendingLoginPopup = nextPendingLoginPopup()
    }

    private func nextPendingLoginPopup() -> PendingLoginPopup? {
        for campaign in gameState.loginCampaigns {
            guard !campaign.rewards.isEmpty else { continue }
            if let rewardState = PlayerInventoryStore.dailyLoginGift(
                from: campaign.rewards,
                progressID: campaign.id,
                in: modelContext
            ) {
                return PendingLoginPopup(
                    campaign: campaign,
                    rewardState: rewardState
                )
            }
        }

        return nil
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
        guard !remoteContent.hasRuntimeRequiredUpdate else { return }

        if hasCompletedIntroFlow, gameState.player.model.isEmpty {
            transition(to: .createClass)
        } else if hasCompletedIntroFlow || introTutorial == nil {
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
        guard !remoteContent.hasRuntimeRequiredUpdate else { return }

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
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await preloadGameEntryAssetsWithoutTimeout()
                return true
            }
            group.addTask {
                try? await Task.sleep(
                    nanoseconds: gameEntryPreloadTimeoutNanoseconds
                )
                return false
            }

            let completedPreload = await group.next() ?? false
            group.cancelAll()
            if !completedPreload {
                await MainActor.run {
                    gameEntryLoadingStatusText =
                        "Assets laden im Hintergrund weiter"
                }
            }
        }
    }

    private func preloadGameEntryAssetsWithoutTimeout() async {
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

        await MainActor.run {
            gameEntryLoadingStatusText = status
        }

        guard !RemoteContentManager.hasCachedOrBundledImage(named: trimmedName)
        else { return }

        await remoteContent.downloadAssetIfNeeded(named: trimmedName)
    }

    private func preloadModelAsset(named assetName: String, status: String)
        async
    {
        let trimmedName = assetName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedName.isEmpty else { return }

        await MainActor.run {
            gameEntryLoadingStatusText = status
        }

        guard
            RemoteContentManager.cachedAssetURL(
                named: trimmedName,
                preferredExtensions: ["usdz", "scn"]
            ) == nil
        else { return }

        await remoteContent.downloadAssetIfNeeded(named: trimmedName)
    }

    private func completeTutorialBattle() {
        if tutorialLaunchSource == .initial,
            !hasCompletedIntroFlow,
            let activeTutorial
        {
            let slotLimit = loadDeckConfiguration().resolvedSlotCount
            for cardReward in activeTutorial.cardRewards
            where cardReward.amount > 0 {
                PlayerInventoryStore.addOwnedCard(
                    cardID: cardReward.cardID,
                    amount: cardReward.amount,
                    in: modelContext
                )
                PlayerInventoryStore.ensureDeckCardEquipped(
                    cardID: cardReward.cardID,
                    preferredSlotIndex: 0,
                    slotLimit: slotLimit,
                    in: modelContext
                )
            }
        }

        if tutorialLaunchSource == .archive || hasCompletedIntroFlow {
            transition(to: .tutorialArchive)
        } else {
            UserDefaults.standard.set(true, forKey: introFlowKey)
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
