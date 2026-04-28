//
//  GameFooterView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameFooterView: View {
    @Binding var selectedTab: GameTab

    private let tabs: [FooterTabItem] = [
        FooterTabItem(
            tab: .game,
            systemName: "house"
        ),
        FooterTabItem(
            tab: .character,
            systemName: "person"
        ),
        FooterTabItem(
            tab: .summon,
            systemName: "sparkles"
        ),
        FooterTabItem(
            tab: .shop,
            systemName: "cart"
        ),
        FooterTabItem(
            tab: .events,
            systemName: "globe.europe.africa"
        ),

    ]

    private var expandedWidth: CGFloat {
        let buttonWidth: CGFloat = 34
        let buttonPadding: CGFloat = 8
        let spacing: CGFloat = 18
        let horizontalInset: CGFloat = 32
        let itemWidth = buttonWidth + (buttonPadding * 2)
        let spacingWidth = CGFloat(max(tabs.count - 1, 0)) * spacing
        return (CGFloat(tabs.count) * itemWidth) + spacingWidth
            + horizontalInset
    }

    private var tabsView: some View {
        HStack(spacing: 18) {
            ForEach(tabs) { item in
                tabButton(item)
            }
        }
    }

    var body: some View {
        tabsView
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(width: expandedWidth)
            .background(
                Color.white.opacity(0.92).background(.ultraThinMaterial)
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.16), radius: 10, y: 3)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
    }

    private func tabButton(_ item: FooterTabItem) -> some View {
        Button {
            selectedTab = item.tab
        } label: {
            Image(systemName: item.systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.gray)
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

}

private struct FooterTabItem: Identifiable {
    let tab: GameTab
    let systemName: String

    var id: GameTab { tab }

    var accessibilityLabel: String {
        switch tab {
        case .game:
            return "Game"
        case .events:
            return "Events"
        case .character:
            return "Character"
        case .shop:
            return "Shop"
        case .support:
            return "Support"
        case .summon:
            return "Summon"
        }
    }
}

#Preview {
    GameFooterView(selectedTab: .constant(.game))
}
