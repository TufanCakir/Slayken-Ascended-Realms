//
//  StartView.swift
//  Valtasia
//
//  Created by Tufan Cakir on 06.03.26.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onStart: () -> Void

    @State private var animate = false

    var body: some View {
        ZStack {

            // MARK: BACKGROUND
            Image("warrior_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack {

                // ⭐ LOGO
                Image("ascended_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400)
                    .scaleEffect(animate ? 1 : 0.8)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.8), value: animate)

            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onStart()
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    StartView(onStart: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
