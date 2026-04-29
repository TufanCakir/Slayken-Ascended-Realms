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
    @StateObject var musicManager = MusicManager()
    @StateObject var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(gameState)
                .environmentObject(theme)
                .environmentObject(musicManager)
                .environmentObject(networkMonitor)
                .onAppear {
                    musicManager.startPlaybackIfNeeded()
                }
        }
        .modelContainer(for: [
            PlayerCurrencyBalance.self,
            OwnedSummonCharacter.self,
            TeamMemberRecord.self,
            PlayerBattleProgress.self,
            PlayerDeckCardSlot.self,
            OwnedAbilityCard.self,
            PlayerCharacterProgress.self,
            PlayerAccountProgress.self,
            SeenCutsceneRecord.self,
            SummonBannerProgress.self,
            PlayerDailyLoginProgress.self,
            PlayerClaimedGift.self,
            ShopOfferProgress.self,
            OwnedCharacterSkin.self,
            ProcessedStoreTransaction.self,
            PlayerQuestClaim.self,
            PlayerQuestCounter.self,
            PlayerDailyBattleRewardCap.self,
            PlayerBattleResourceState.self,
        ])
    }
}
