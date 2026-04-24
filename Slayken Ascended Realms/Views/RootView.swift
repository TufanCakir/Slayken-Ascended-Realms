//
//  RootView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.modelContext) private var modelContext

    private enum Screen {
        case start
        case game
        case battle
    }

    @State private var currentScreen: Screen = .start
    @State private var activeEnemy: CharacterStats?
    @State private var isLoading = false
    @State private var loadingProgress = 0.0
    @State private var loadingBackground = "bg_epic"
    @State private var loadingTask: Task<Void, Never>?
    @State private var pendingDailyReward: DailyLoginRewardState?

    private let dailyLoginRewards = loadDailyLoginRewardDefinitions()

    var body: some View {
        ZStack {
            switch currentScreen {
            case .start:
                StartView {
                    transition(to: .game)
                }

            case .game:
                GameView(onResetGame: {
                    resetToStart()
                }) { enemy in
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
        }
        .animation(.smooth(duration: 0.45), value: currentScreenID)
        .onAppear {
            refreshDailyGift()
        }
        .onDisappear {
            loadingTask?.cancel()
        }
    }

    private var currentScreenID: String {
        switch currentScreen {
        case .start:
            return "start"
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
                "bg_epic", "sar_bg", "map", "country", "bg_arena", "fire", "ice", "void",
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
        loadingBackground = images.randomElement() ?? "sar_bg"

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
}

#Preview {
    RootView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
