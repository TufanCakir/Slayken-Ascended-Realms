//
//  Slayken_Ascended_RealmsApp.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

@main
struct Slayken_Ascended_RealmsApp: App {

    @StateObject var gameState = GameState()
    @StateObject var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            StartView()
                .environmentObject(gameState)
                .environmentObject(theme)
        }
    }
}
