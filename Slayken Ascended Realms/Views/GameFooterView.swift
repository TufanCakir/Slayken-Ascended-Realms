//
//  GameFooterView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameFooterView: View {
    @Binding var selectedTab: GameTab
    @State private var isExpanded = true

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
        HStack(spacing: 8) {
            Spacer(minLength: 0)

            tabsView
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(
                    width: isExpanded ? expandedWidth : 0,
                    alignment: .trailing
                )
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
