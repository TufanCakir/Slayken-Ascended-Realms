//
//  GameMiddleDrawerView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameMiddleDrawerView: View {
    @Binding var selectedTab: GameTab

    let onTheme: () -> Void
    let onSupport: () -> Void
    let onNews: () -> Void
    let onCreateClass: () -> Void
    let onShop: () -> Void
    let onQuests: () -> Void
    let onArchive: () -> Void
    let onEventArchive: () -> Void
    let onTutorialArchive: () -> Void
    let onGift: () -> Void
    let onDailyLogin: () -> Void
    let onSettings: () -> Void
    let trailingPadding: CGFloat

    @State private var isExpanded = false
    @State private var showMoreActions = false

    private let actions: [MiddleDrawerActionItem] = [
        MiddleDrawerActionItem(
            id: .home,
            title: "Dojo",
            systemName: "figure.martial.arts"
        ),
        MiddleDrawerActionItem(
            id: .team,
            title: "Fighter",
            systemName: "person.crop.square"
        ),
        MiddleDrawerActionItem(
            id: .events,
            title: "Arena",
            systemName: "sportscourt"
        ),
        MiddleDrawerActionItem(
            id: .summon,
            title: "Roster",
            systemName: "sparkles"
        ),
        MiddleDrawerActionItem(
            id: .shop,
            title: "Market",
            systemName: "bag"
        ),
        MiddleDrawerActionItem(
            id: .more,
            title: "More",
            systemName: "ellipsis"
        ),
    ]

    var body: some View {
        HStack(spacing: 6) {
            drawerContent
                .frame(width: isExpanded ? 138 : 0, alignment: .trailing)
                .clipped()
                .opacity(isExpanded ? 1 : 0)

            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 0) {
                    Text("Menu")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(.degrees(90))
                        .fixedSize()
                }
                .foregroundStyle(.black)
                .frame(width: 28, height: 84)
                .background(.white, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isExpanded ? "Close Menu Drawer" : "Open Menu Drawer"
            )
        }
        .padding(.trailing, trailingPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .animation(
            .spring(response: 0.34, dampingFraction: 0.84),
            value: isExpanded
        )
        .sheet(isPresented: $showMoreActions) {
            moreActionsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var drawerContent: some View {
        VStack(spacing: 8) {
            ForEach(actions) { item in
                actionButton(item)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
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
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .frame(width: 116, height: 32)
            .background(
                isActive(item.id)
                    ? Color.red.opacity(0.58) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
    }

    private var moreActionsSheet: some View {
        NavigationStack {
            List {
                Section("Training") {
                    moreAction("Quests", "checklist", onQuests)
                    moreAction(
                        "Classes",
                        "person.crop.rectangle.stack",
                        onCreateClass
                    )
                    moreAction(
                        "Tutorial",
                        "play.rectangle.on.rectangle",
                        onTutorialArchive
                    )
                }

                Section("Archive") {
                    moreAction("Story", "book", onArchive)
                    moreAction(
                        "Event Log",
                        "sparkles.rectangle.stack",
                        onEventArchive
                    )
                    moreAction("News", "newspaper", onNews)
                }

                Section("Account") {
                    moreAction("Gift", "gift", onGift)
                    moreAction(
                        "Daily Login",
                        "calendar.badge.clock",
                        onDailyLogin
                    )
                    moreAction("Theme", "paintbrush", onTheme)
                    moreAction("Support", "questionmark.circle", onSupport)
                    moreAction("Settings", "gear", onSettings)
                }
            }
            .navigationTitle("Fighter Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func moreAction(
        _ title: String,
        _ systemName: String,
        _ action: @escaping () -> Void
    ) -> some View {
        Button {
            showMoreActions = false
            selectedTab = .game
            action()
        } label: {
            Label(title, systemImage: systemName)
        }
    }

    private func perform(_ action: MiddleDrawerAction) {
        switch action {
        case .home:
            selectedTab = .game
        case .theme:
            selectedTab = .game
            onTheme()
        case .events:
            selectedTab = .events
        case .team:
            selectedTab = .character
        case .createClass:
            selectedTab = .game
            onCreateClass()
        case .summon:
            selectedTab = .summon
        case .shop:
            selectedTab = .game
            onShop()
        case .quests:
            selectedTab = .game
            onQuests()
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
        case .more:
            selectedTab = .game
            showMoreActions = true
        }
    }

    private func isActive(_ action: MiddleDrawerAction) -> Bool {
        switch action {
        case .home:
            return selectedTab == .game
        case .theme:
            return false
        case .events:
            return selectedTab == .events
        case .team:
            return selectedTab == .character
        case .createClass:
            return false
        case .summon:
            return selectedTab == .summon
        case .shop:
            return false
        case .quests:
            return false
        case .news, .archive, .tutorialArchive, .eventArchive, .gift,
            .dailyLogin:
            return false
        case .support:
            return selectedTab == .support
        case .settings:
            return false
        case .more:
            return false
        }
    }
}

private enum MiddleDrawerAction {
    case home
    case theme
    case events
    case team
    case createClass
    case summon
    case shop
    case quests
    case news
    case archive
    case tutorialArchive
    case eventArchive
    case gift
    case dailyLogin
    case support
    case settings
    case more
}

private struct MiddleDrawerActionItem: Identifiable {
    let id: MiddleDrawerAction
    let title: String
    let systemName: String
}
