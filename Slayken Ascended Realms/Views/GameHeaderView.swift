//
//  GameHeaderView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 17.04.26.
//

import SwiftUI
import UIKit

struct GameHeaderView: View {
    let onBackground: () -> Void
    let onMap: () -> Void
    let onTheme: () -> Void
    let onSupport: () -> Void

    @State private var isExpanded = true

    private let actions: [HeaderActionItem]

    init(
        onBackground: @escaping () -> Void,
        onMap: @escaping () -> Void,
        onTheme: @escaping () -> Void,
        onSupport: @escaping () -> Void
    ) {
        self.onBackground = onBackground
        self.onMap = onMap
        self.onTheme = onTheme
        self.onSupport = onSupport
        self.actions = [
            HeaderActionItem(id: .background, imageName: "background", fallbackSystemName: "photo"),
            HeaderActionItem(id: .map, imageName: "map", fallbackSystemName: "map"),
            HeaderActionItem(id: .theme, imageName: "theme", fallbackSystemName: "paintbrush"),
            HeaderActionItem(id: .support, imageName: "support", fallbackSystemName: "questionmark.circle"),
        ]
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)

            HStack(spacing: 18) {
                ForEach(actions) { item in
                    actionButton(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(width: isExpanded ? 244 : 0, alignment: .trailing)
            .clipped()
            .background(
                Color.white.opacity(isExpanded ? 0.92 : 0)
                    .background(isExpanded ? .ultraThinMaterial : .regularMaterial)
            )
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(isExpanded ? 0.16 : 0),
                radius: 10,
                y: 3
            )
            .opacity(isExpanded ? 1 : 0)
            .animation(.spring(response: 0.36, dampingFraction: 0.84), value: isExpanded)

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

    private func actionButton(_ item: HeaderActionItem) -> some View {
        Button {
            perform(item.id)
        } label: {
            headerIcon(item)
                .frame(width: 34, height: 34)
                .padding(4)
                .background(
                    Color.black.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
    }

    @ViewBuilder
    private func headerIcon(_ item: HeaderActionItem) -> some View {
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

    private func perform(_ action: HeaderAction) {
        switch action {
        case .background:
            onBackground()
        case .map:
            onMap()
        case .theme:
            onTheme()
        case .support:
            onSupport()
        }
    }
}

private enum HeaderAction {
    case background
    case map
    case theme
    case support
}

private struct HeaderActionItem: Identifiable {
    let id: HeaderAction
    let imageName: String
    let fallbackSystemName: String

    var accessibilityLabel: String {
        switch id {
        case .background:
            return "Background"
        case .map:
            return "Map"
        case .theme:
            return "Theme"
        case .support:
            return "Support"
        }
    }
}

#Preview {
    GameHeaderView(
        onBackground: {},
        onMap: {},
        onTheme: {},
        onSupport: {}
    )
}
