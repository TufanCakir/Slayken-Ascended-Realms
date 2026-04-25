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
                if let current = theme.selectedTheme {
                    Image(current.background)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.18),
                            Color.black.opacity(0.58),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                        ],
                        spacing: 10
                    ) {
                        ForEach(theme.themes) { item in
                            Button {
                                theme.select(item)
                                onClose()
                            } label: {
                                ZStack(alignment: .bottomLeading) {
                                    Image(item.background)
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 18)
                                        )

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
                                        .padding()
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
                    .padding(.horizontal, 50)
                }
            }
        }
    }
}

#Preview {
    ThemeSelectView(onClose: {})
        .environmentObject(ThemeManager())
}
