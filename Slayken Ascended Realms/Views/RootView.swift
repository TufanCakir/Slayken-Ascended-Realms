//
//  RootView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 12.04.26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    private enum Screen {
        case start
        case game
        case battle
    }

    @State private var currentScreen: Screen = .start
    @State private var activeEnemy: CharacterStats?
    @State private var isLoading = false
    @State private var loadingProgress = 0.0
    @State private var loadingBackground = "sar_bg"
    @State private var loadingTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            switch currentScreen {
            case .start:
                StartView {
                    transition(to: .game)
                }

            case .game:
                GameView { enemy in
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
        }
        .animation(.smooth(duration: 0.45), value: currentScreenID)
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
                "sar_bg", "map", "country", "bg_arena", "fire", "ice", "void",
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
}

#Preview {
    RootView()
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
