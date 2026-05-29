//
//  GameFooterView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameFooterView: View {
    @Binding var selectedTab: GameTab
    var onSelectTab: ((GameTab) -> Void)?

    private let tabs: [FooterTabItem] = [
        FooterTabItem(
            tab: .game,
            systemName: "figure.martial.arts"
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
            systemName: "sportscourt"
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
            .background(Color.black.opacity(0.78))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.26), radius: 12, y: 4)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
    }

    private func tabButton(_ item: FooterTabItem) -> some View {
        Button {
            onSelectTab?(item.tab)
            selectedTab = item.tab
        } label: {
            Image(systemName: item.systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(selectedTab == item.tab ? .white : .white.opacity(0.62))
                .frame(width: 34, height: 34)
                .padding(4)
                .background(
                    selectedTab == item.tab
                        ? Color.red.opacity(0.62) : Color.white.opacity(0.08),
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
            return "Dojo"
        case .events:
            return "Arena"
        case .character:
            return "Fighter"
        case .shop:
            return "Market"
        case .support:
            return "Support"
        case .summon:
            return "Summon"
        }
    }
}
