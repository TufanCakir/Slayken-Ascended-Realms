//
//  ThemeSelectView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct ThemeSelectView: View {

    @EnvironmentObject var theme: ThemeManager
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌑 BACKGROUND (aktuelles Theme)
                if let current = theme.selectedTheme {

                    LinearGradient(
                        colors: [
                            current.primary.color,
                            current.secondary.color,
                            current.accent.color,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ]
                    ) {
                        ForEach(theme.themes) { item in
                            Button {
                                theme.select(item)
                                onClose()
                            } label: {

                                ZStack(alignment: .bottomLeading) {

                                    // 🎨 THEME PREVIEW
                                    LinearGradient(
                                        colors: [
                                            item.primary.color,
                                            item.secondary.color,
                                            item.accent.color,
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(height: 120)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 18)
                                    )

                                    // 🌘 DARK OVERLAY
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 18)
                                    )

                                    // 🏷 NAME
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(8)
                                }
                                .overlay {
                                    if theme.selectedTheme?.id == item.id {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                item.primary.color,
                                                lineWidth: 3
                                            )
                                            .shadow(
                                                color: item.glow.color.opacity(
                                                    0.8
                                                ),
                                                radius: 10
                                            )
                                    }
                                }
                                .scaleEffect(
                                    theme.selectedTheme?.id == item.id
                                        ? 1.05 : 1.0
                                )
                                .animation(
                                    .easeInOut(duration: 0.2),
                                    value: theme.selectedTheme?.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    ThemeSelectView(onClose: {})
        .environmentObject(ThemeManager())
}
