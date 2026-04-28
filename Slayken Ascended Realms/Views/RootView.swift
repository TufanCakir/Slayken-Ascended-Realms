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
    @EnvironmentObject var networkMonitor: NetworkMonitor
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
    @State private var isLoading = false
    @State private var loadingProgress = 0.0
    @State private var loadingBackground = "theme_epic"
    @State private var loadingTask: Task<Void, Never>?
    @State private var pendingDailyReward: DailyLoginRewardState?
    @State private var activeTutorial: GameTutorialDefinition?
    @State private var activeIntroIndex = 0
    @State private var tutorialLaunchSource: TutorialLaunchSource = .initial

    private let dailyLoginRewards = loadDailyLoginRewardDefinitions()
    private let introVideos = loadIntroVideoDefinitions()
    private let tutorials = loadTutorialDefinitions()
    private let introFlowKey = "hasCompletedIntroFlow"

    var body: some View {
        ZStack {
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
                CreateClassView {
                    completeClassCreation(with: $0)
                }
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

            if isLoading {
                LoadingOverlayView(
                    progress: loadingProgress,
                    background: loadingBackground
                )
                .environmentObject(theme)
                .zIndex(100)
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
            refreshDailyGift()
        }
        .onDisappear {
            loadingTask?.cancel()
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
                    "Slayken Ascended Realms kann aktuell nur mit aktiver Internetverbindung gespielt werden. Bitte verbinde dich mit dem Internet."
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
                "theme_epic", "theme_fire", "sar_bg", "map", "country",
                "bg_arena", "fire",
                "ice", "void",
            ]
        }

        var seen = Set<String>()
        return assets.filter { seen.insert($0).inserted }
    }

    private func transition(to screen: Screen, enemy: CharacterStats? = nil) {
        loadingTask?.cancel()
        loadingTask = Task {
            await runLoadingTransition(to: screen, enemy: enemy)
        }
    }

    private func resetToStart() {
        loadingTask?.cancel()
        gameState.clearBattleSelection()
        activeEnemy = nil
        activeIntroIndex = 0
        activeTutorial = nil
        loadingProgress = 0
        refreshDailyGift()

        withAnimation(.smooth(duration: 0.35)) {
            isLoading = false
            currentScreen = .start
        }
    }

    @MainActor
    private func runLoadingTransition(to screen: Screen, enemy: CharacterStats?)
        async
    {
        let images = loadingImages
        loadingProgress = 0
        loadingBackground = images.randomElement() ?? "bg_sar"

        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
        }

        let steps = 24
        for step in 1...steps {
            if Task.isCancelled {
                return
            }

            try? await Task.sleep(for: .milliseconds(70))

            let progress = Double(step) / Double(steps)

            withAnimation(.linear(duration: 0.07)) {
                loadingProgress = progress
            }
        }

        withAnimation(.smooth(duration: 0.45)) {
            activeEnemy = enemy
            currentScreen = screen
            if screen != .battle {
                activeEnemy = nil
            }
        }

        try? await Task.sleep(for: .milliseconds(120))

        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = false
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
            transition(to: .game)
        } else if !openingIntroVideos.isEmpty {
            activeIntroIndex = 0
            tutorialLaunchSource = .initial
            transition(to: .introVideo)
        } else {
            beginTutorialBattle()
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
}
