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
        FooterTabItem(tab: .game, imageName: "game", fallbackSystemName: "gamecontroller"),
        FooterTabItem(tab: .map, imageName: "map", fallbackSystemName: "map"),
        FooterTabItem(tab: .character, imageName: "character", fallbackSystemName: "person"),
    ]

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.left" : "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: 34, height: 58)
                    .background(.white.opacity(0.92), in: Capsule())
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
            }
            .buttonStyle(.plain)

            HStack(spacing: 38) {
                ForEach(tabs) { item in
                    tabButton(item)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .frame(width: isExpanded ? 252 : 0, alignment: .leading)
            .clipped()
            .background(
                Color.white.opacity(isExpanded ? 0.92 : 0)
                    .background(isExpanded ? .ultraThinMaterial : .regularMaterial)
            )
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(isExpanded ? 0.14 : 0),
                radius: 12,
                y: 3
            )
            .opacity(isExpanded ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.84), value: isExpanded)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
         }

    private func tabButton(_ item: FooterTabItem) -> some View {
        let isSelected = selectedTab == item.tab

        return Button {
            selectedTab = item.tab
        } label: {
            footerIcon(item)
                .frame(width: 44, height: 44)
                .padding(2)
                .background(
                    isSelected ? Color.black.opacity(0.08) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    }
                }
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
                .font(.system(size: 21, weight: .medium))
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
        }
    }
}

#Preview {
    GameFooterView(selectedTab: .constant(.game))
}
