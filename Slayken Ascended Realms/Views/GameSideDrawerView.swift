//
//  GameSideDrawerView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameSideDrawerView: View {
    let onTheme: () -> Void
    let onSupport: () -> Void
    let onNews: () -> Void
    let onSettings: () -> Void

    @State private var isExpanded = false

    private let actions: [SideDrawerActionItem]

    init(
        showTheme: Bool = true,
        showSupport: Bool = true,
        showNews: Bool = true,
        showSettings: Bool = true,
        onTheme: @escaping () -> Void,
        onSupport: @escaping () -> Void,
        onNews: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {}
    ) {
        self.onTheme = onTheme
        self.onSupport = onSupport
        self.onNews = onNews
        self.onSettings = onSettings

        var drawerActions: [SideDrawerActionItem] = []
        if showTheme {
            drawerActions.append(
                SideDrawerActionItem(id: .theme, systemName: "paintbrush")
            )
        }
        if showNews {
            drawerActions.append(
                SideDrawerActionItem(id: .news, systemName: "newspaper")
            )
        }
        if showSupport {
            drawerActions.append(
                SideDrawerActionItem(
                    id: .support,
                    systemName: "questionmark.circle"
                )
            )
        }
        if showSettings {
            drawerActions.append(
                SideDrawerActionItem(
                    id: .settings,
                    systemName: "gearshape.fill"
                )
            )
        }
        self.actions = drawerActions
    }

    var body: some View {
        HStack(spacing: 8) {
            drawerContent
                .frame(
                    width: isExpanded ? drawerWidth : 0,
                    alignment: .trailing
                )
                .clipped()
                .opacity(isExpanded ? 1 : 0)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.right" : "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: 34, height: 54)
                    .background(.white.opacity(0.92), in: Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Close Drawer" : "Open Drawer")
        }
        .padding(.trailing, 10)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .animation(
            .spring(response: 0.34, dampingFraction: 0.84),
            value: isExpanded
        )
    }

    private var drawerWidth: CGFloat {
        CGFloat(actions.count * 42 + max(0, actions.count - 1) * 10 + 18)
    }

    private var drawerContent: some View {
        HStack(spacing: 10) {
            ForEach(actions) { item in
                actionButton(item)
            }
        }
        .padding(9)
        .background(Color.white.opacity(0.90).background(.ultraThinMaterial))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    private func actionButton(_ item: SideDrawerActionItem) -> some View {
        Button {
            perform(item.id)
        } label: {
            Image(systemName: item.systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.gray)
                .frame(width: 34, height: 34)
                .padding(4)
                .background(
                    Color.black.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
    }

    private func perform(_ action: SideDrawerAction) {
        switch action {
        case .theme:
            onTheme()
        case .news:
            onNews()
        case .support:
            onSupport()
        case .settings:
            onSettings()
        }
    }
}

private enum SideDrawerAction {
    case theme
    case news
    case support
    case settings
}

private struct SideDrawerActionItem: Identifiable {
    let id: SideDrawerAction
    let systemName: String

    var accessibilityLabel: String {
        switch id {
        case .theme:
            return "Theme"
        case .news:
            return "News"
        case .support:
            return "Support"
        case .settings:
            return "Settings"
        }
    }
}
