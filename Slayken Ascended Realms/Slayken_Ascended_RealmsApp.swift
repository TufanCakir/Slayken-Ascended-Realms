//
//  Slayken_Ascended_RealmsApp.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

@main
struct Slayken_Ascended_RealmsApp: App {

    @StateObject var gameState = GameState()
    @StateObject var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
                .environmentObject(theme)
        }
        .modelContainer(for: [
            PlayerCurrencyBalance.self,
            OwnedSummonCharacter.self,
            TeamMemberRecord.self,
            PlayerBattleProgress.self,
            PlayerDeckCardSlot.self,
            OwnedAbilityCard.self,
            PlayerCharacterProgress.self,
        ])
    }
}
