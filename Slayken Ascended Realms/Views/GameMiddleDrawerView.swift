//
//  GameMiddleDrawerView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameMiddleDrawerView: View {
    @Binding var selectedTab: GameTab

    let onSupport: () -> Void
    let onNews: () -> Void
    let onCreateClass: () -> Void
    let onArchive: () -> Void
    let onEventArchive: () -> Void
    let onTutorialArchive: () -> Void
    let onGift: () -> Void
    let onDailyLogin: () -> Void
    let onSettings: () -> Void

    @State private var isExpanded = false

    private let actions: [MiddleDrawerActionItem] = [
        MiddleDrawerActionItem(id: .home, title: "Home", systemName: "house"),
        MiddleDrawerActionItem(
            id: .events,
            title: "Events",
            systemName: "globe.europe.africa"
        ),
        MiddleDrawerActionItem(id: .team, title: "Team", systemName: "person"),
        MiddleDrawerActionItem(
            id: .createClass,
            title: "Classes",
            systemName: "person.crop.rectangle.stack"
        ),
        MiddleDrawerActionItem(
            id: .summon,
            title: "Summon",
            systemName: "sparkles"
        ),
        MiddleDrawerActionItem(
            id: .news,
            title: "News",
            systemName: "newspaper"
        ),
        MiddleDrawerActionItem(
            id: .archive,
            title: "Story",
            systemName: "book"
        ),
        MiddleDrawerActionItem(
            id: .tutorialArchive,
            title: "Tutorial",
            systemName: "play.rectangle.on.rectangle"
        ),
        MiddleDrawerActionItem(
            id: .eventArchive,
            title: "Event Log",
            systemName: "sparkles.rectangle.stack"
        ),
        MiddleDrawerActionItem(
            id: .gift,
            title: "Gift",
            systemName: "gift"
        ),
        MiddleDrawerActionItem(
            id: .dailyLogin,
            title: "Daily",
            systemName: "calendar.badge.clock"
        ),
        MiddleDrawerActionItem(
            id: .support,
            title: "Support",
            systemName: "questionmark.circle"
        ),
        MiddleDrawerActionItem(
            id: .settings,
            title: "Settings",
            systemName: "gear"
        ),
    ]

    var body: some View {
        HStack(spacing: 8) {
            drawerContent
                .frame(width: isExpanded ? 148 : 0, alignment: .trailing)
                .clipped()
                .opacity(isExpanded ? 1 : 0)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 0) {
                    Text("Menu")
                        .font(.system(size: 15)).bold()
                        .rotationEffect(.degrees(90))
                        .fixedSize()
                }
                .foregroundStyle(.black)
                .frame(width: 30, height: 100)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isExpanded ? "Close Menu Drawer" : "Open Menu Drawer"
            )
        }
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .animation(
            .spring(response: 0.34, dampingFraction: 0.84),
            value: isExpanded
        )
    }

    private var drawerContent: some View {
        VStack(spacing: 8) {
            ForEach(actions) { item in
                actionButton(item)
            }
        }
        .padding(9)
        .background(Color.white.opacity(0.90).background(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }

    private func actionButton(_ item: MiddleDrawerActionItem) -> some View {
        Button {
            perform(item.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.systemName)
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 22, height: 22)

                Text(item.title)
                    .font(.system(size: 12, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }
            .foregroundStyle(.gray)
            .padding(.horizontal, 8)
            .frame(width: 124, height: 34)
            .background(
                Color.black.opacity(isActive(item.id) ? 0.12 : 0.06),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }

    private func perform(_ action: MiddleDrawerAction) {
        switch action {
        case .home:
            selectedTab = .game
        case .events:
            selectedTab = .events
        case .team:
            selectedTab = .character
        case .createClass:
            selectedTab = .game
            onCreateClass()
        case .summon:
            selectedTab = .summon
        case .news:
            selectedTab = .game
            onNews()
        case .archive:
            selectedTab = .game
            onArchive()
        case .tutorialArchive:
            selectedTab = .game
            onTutorialArchive()
        case .eventArchive:
            selectedTab = .game
            onEventArchive()
        case .gift:
            selectedTab = .game
            onGift()
        case .dailyLogin:
            selectedTab = .game
            onDailyLogin()
        case .support:
            selectedTab = .game
            onSupport()
        case .settings:
            selectedTab = .game
            onSettings()
        }
    }

    private func isActive(_ action: MiddleDrawerAction) -> Bool {
        switch action {
        case .home:
            return selectedTab == .game
        case .events:
            return selectedTab == .events
        case .team:
            return selectedTab == .character
        case .createClass:
            return false
        case .summon:
            return selectedTab == .summon
        case .news, .archive, .tutorialArchive, .eventArchive, .gift,
            .dailyLogin:
            return false
        case .support:
            return selectedTab == .support
        case .settings:
            return false
        }
    }
}

private enum MiddleDrawerAction {
    case home
    case events
    case team
    case createClass
    case summon
    case news
    case archive
    case tutorialArchive
    case eventArchive
    case gift
    case dailyLogin
    case support
    case settings
}

private struct MiddleDrawerActionItem: Identifiable {
    let id: MiddleDrawerAction
    let title: String
    let systemName: String
}

#Preview {
    GameMiddleDrawerView(
        selectedTab: .constant(.game),
        onSupport: {},
        onNews: {},
        onCreateClass: {},
        onArchive: {},
        onEventArchive: {},
        onTutorialArchive: {},
        onGift: {},
        onDailyLogin: {},
        onSettings: {}
    )
}
