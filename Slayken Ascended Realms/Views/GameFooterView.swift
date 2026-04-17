//
//  GameFooterView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 17.04.26.
//

import SwiftUI
import UIKit

struct GameFooterView: View {
    @Binding var selectedTab: GameTab
    @State private var isExpanded = true

    private let tabs: [FooterTabItem] = [
        FooterTabItem(
            tab: .game,
            imageName: "game",
            fallbackSystemName: "gamecontroller"
        ),
        FooterTabItem(tab: .map, imageName: "map", fallbackSystemName: "map"),
        FooterTabItem(
            tab: .character,
            imageName: "character",
            fallbackSystemName: "person"
        ),
        FooterTabItem(
            tab: .support,
            imageName: "support",
            fallbackSystemName: "questionmark.circle"
        ),
    ]

    private var tabsView: some View {
        HStack(spacing: 18) {
            ForEach(tabs) { item in
                tabButton(item)
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)

            tabsView
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(width: isExpanded ? 244 : 0, alignment: .trailing)
                .clipped()
                .background(
                    Color.white.opacity(isExpanded ? 0.92 : 0)
                        .background(
                            isExpanded ? .ultraThinMaterial : .regularMaterial
                        )
                )
                .clipShape(Capsule())
                .shadow(
                    color: .black.opacity(isExpanded ? 0.16 : 0),
                    radius: 10,
                    y: 3
                )
                .opacity(isExpanded ? 1 : 0)
                .animation(
                    .spring(response: 0.36, dampingFraction: 0.84),
                    value: isExpanded
                )

            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: 34, height: 46)
                    .background(.white.opacity(0.92), in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func tabButton(_ item: FooterTabItem) -> some View {
        Button {
            selectedTab = item.tab
        } label: {
            footerIcon(item)
                .frame(width: 34, height: 34)
                .padding(4)
                .background(
                    Color.black.opacity(selectedTab == item.tab ? 0.08 : 0.06),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
    }

    @ViewBuilder
    private func footerIcon(_ item: FooterTabItem) -> some View {
        if let image = UIImage(named: item.imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: item.fallbackSystemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.gray)
        }
    }
}

private struct FooterTabItem: Identifiable {
    let tab: GameTab
    let imageName: String
    let fallbackSystemName: String

    var id: GameTab { tab }

    var accessibilityLabel: String {
        switch tab {
        case .game:
            return "Game"
        case .map:
            return "Map"
        case .character:
            return "Character"
        case .support:
            return "Support"
        }
    }
}

#Preview {
    GameFooterView(selectedTab: .constant(.game))
}
