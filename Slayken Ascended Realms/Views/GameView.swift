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
    private let player = loadGamePlayer()
    
    let onStartBattle: (CharacterStats) -> Void

    let rows = [
        GridItem(.fixed(90)),
        GridItem(.fixed(90)),
    ]

    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                
                // ✅ 3D FULLSCREEN
                GameSceneView(
                    player: player,
                    joystickVector: joystickVector,
                    groundTexture: gameState.selectedMap.mapImage,
                    skyboxTexture: gameState.selectedBackground.image
                )
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

                VStack {
                    Spacer()

                    JoystickView(vector: $joystickVector)
                        .padding(.bottom, 12)

                    ZStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: rows, spacing: 16) {
                                ForEach(gameState.maps) { map in
                                    levelButton(map: map)
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(height: geo.size.height * 0.25)
                    .background(.ultraThinMaterial)
                }
                .overlay(alignment: .topTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                activeSelectionSheet = .background
                            } label: {
                                Image(systemName: "photo")
                            }

                            Button {
                                activeSelectionSheet = .map
                            } label: {
                                Image(systemName: "map")
                            }

                            Button {
                                activeSelectionSheet = .theme
                            } label: {
                                Image(systemName: "paintbrush")
                            }

                            // 🆘 Support Button
                            Button {
                                showSupport = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.35), in: Capsule())
                        .padding(.top, 12)
                        .padding(.trailing, 16)
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
        }
    }
    

    private func levelButton(map: GameMap) -> some View {
        Button {
            gameState.selectedMap = map
            selectedEnemy = map.enemy
            currentStory = map.story

            withAnimation(.easeInOut(duration: 0.25)) {
                showPopup = false
                showStory = true
            }
        } label: {
            ZStack(alignment: .bottomLeading) {

                Image(map.mapImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 100)
                    .clipped()

                Text(map.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: 180, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                if gameState.selectedMap.id == map.id {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white, lineWidth: 3)
                }
            }
        }
    }
}

#Preview {
    GameView { _ in }
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
