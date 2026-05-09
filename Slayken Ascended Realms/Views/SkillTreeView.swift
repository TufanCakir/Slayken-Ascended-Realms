//
//  SkillTreeView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct SkillTreeView: View {
    let character: CharacterStats
    let onClose: () -> Void

    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \PlayerCurrencyBalance.code) private var balances:
        [PlayerCurrencyBalance]

    @State private var selectedNodeID: String?
    @State private var selectedTreeID: String?
    @State private var presentedNodeID: String?
    @State private var showsTreeSelector = false
    @State private var showsAutoUnlockConfirmation = false
    @State private var autoUnlockMessage = ""
    @State private var refreshID = UUID()

    private var skillTrees: [CharacterSkillTreeDefinition] {
        loadCharacterSkillTrees()
    }

    private var skillTree: CharacterSkillTreeDefinition? {
        if let selectedTreeID,
            let matchingTree = skillTrees.first(where: {
                $0.id == selectedTreeID
            })
        {
            return matchingTree
        }

        return skillTrees.first
    }

    private var nodeRanks: [String: Int] {
        _ = refreshID
        return PlayerInventoryStore.skillNodeRanks(
            for: character.model,
            in: modelContext
        )
    }

    private var presentedNode: CharacterSkillNodeDefinition? {
        guard let presentedNodeID else {
            return nil
        }
        return skillTree?.nodes.first { $0.id == presentedNodeID }
    }

    private var skillBonuses: CharacterSkillBonusTotals {
        PlayerInventoryStore.characterSkillBonuses(
            for: character.model,
            in: modelContext
        )
    }

    private var displayedCurrencies: [CurrencyDefinition] {
        let requiredCodes = Set(
            skillTrees.flatMap { tree in
                tree.nodes.map(\.costCurrency)
            }
        )
        return gameState.currencies
            .filter { requiredCodes.contains($0.code) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var canvasScale: CGFloat {
        isCompactLayout ? 0.78 : 1.0
    }

    private var canvasSize: CGSize {
        CGSize(
            width: isCompactLayout ? 660 : 900,
            height: isCompactLayout ? 440 : 620
        )
    }

    private var nodeSize: CGSize {
        CGSize(
            width: isCompactLayout ? 104 : 132,
            height: isCompactLayout ? 88 : 114
        )
    }

    var body: some View {
        Group {
            if let skillTree {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isCompactLayout ? 10 : 16) {
                        header(for: skillTree)
                        if showsTreeSelector {
                            treeSelector
                        }
                        currencyStrip(for: skillTree)
                        content(for: skillTree)
                    }
                    .padding(.horizontal, isCompactLayout ? 10 : 16)
                    .padding(.top, isCompactLayout ? 18 : 52)
                    .padding(.bottom, isCompactLayout ? 10 : 18)
                }
            } else {
                unavailableState
            }
        }
        .onAppear {
            selectedTreeID = selectedTreeID ?? firstAvailableTreeID
            selectedNodeID = selectedNodeID ?? skillTree?.nodes.first?.id
        }
        .onChange(of: skillTrees.map(\.id)) { _, treeIDs in
            if !treeIDs.contains(selectedTreeID ?? "") {
                selectedTreeID = firstAvailableTreeID
            }
        }
        .onChange(of: selectedTreeID) { _, _ in
            selectedNodeID = skillTree?.nodes.first?.id
        }
        .onChange(of: refreshID) { _, _ in
            if let selectedTreeID, !isTreeUnlocked(selectedTreeID) {
                self.selectedTreeID = firstAvailableTreeID
            }
        }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    RemoteAssetImage(theme.background) {
                        Color.black.opacity(0.35)
                    }
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.6),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
        .alert(
            presentedNode?.title ?? "Skill",
            isPresented: Binding(
                get: { presentedNode != nil },
                set: { isPresented in
                    if !isPresented {
                        presentedNodeID = nil
                    }
                }
            ),
            presenting: presentedNode
        ) { node in
            Button("Abbrechen", role: .cancel) {
                presentedNodeID = nil
            }
            Button("Skill lernen") {
                guard let skillTree else { return }
                if PlayerInventoryStore.learnSkillNode(
                    node,
                    in: skillTree,
                    characterID: character.model,
                    in: modelContext
                ) {
                    refreshID = UUID()
                }
                presentedNodeID = nil
            }
            .disabled(
                !(skillTree.map {
                    PlayerInventoryStore.canLearnSkillNode(
                        node,
                        in: $0,
                        characterID: character.model,
                        in: modelContext
                    )
                } ?? false)
            )
        } message: { node in
            Text(nodePopupSummary(for: node))
        }
        .alert("Auto Unlock", isPresented: $showsAutoUnlockConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Alles lernen") {
                guard let skillTree else { return }
                performAutoUnlock(in: skillTree)
            }
        } message: {
            Text(autoUnlockConfirmationText)
        }
    }

    private func header(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .frame(
                        width: isCompactLayout ? 34 : 38,
                        height: isCompactLayout ? 34 : 38
                    )
                    .background(Color.black.opacity(0.42), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                showsTreeSelector.toggle()
            } label: {
                Image(
                    systemName: showsTreeSelector
                        ? "rectangle.compress.vertical"
                        : "arrow.triangle.branch"
                )
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .frame(
                    width: isCompactLayout ? 34 : 38,
                    height: isCompactLayout ? 34 : 38
                )
                .background(Color.black.opacity(0.42), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func currencyStrip(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isCompactLayout ? 7 : 10) {
                ForEach(displayedCurrencies) { currency in
                    let amount =
                        balances.first { $0.code == currency.code }?.amount ?? 0

                    HStack(spacing: isCompactLayout ? 5 : 8) {
                        currencyIcon(for: currency)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.name)
                                .font(
                                    .system(
                                        size: isCompactLayout ? 8 : 10,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white.opacity(0.78))
                            Text("\(amount)")
                                .font(
                                    .system(
                                        size: isCompactLayout ? 11 : 13,
                                        weight: .black
                                    )
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, isCompactLayout ? 9 : 12)
                    .padding(.vertical, isCompactLayout ? 6 : 9)
                    .background(
                        LinearGradient(
                            colors: [
                                color(
                                    from: skillTree.palette?
                                        .resourceBarStartHex,
                                    fallback: Color(
                                        red: 0.11,
                                        green: 0.40,
                                        blue: 0.57
                                    )
                                ),
                                color(
                                    from: skillTree.palette?.resourceBarEndHex,
                                    fallback: Color(
                                        red: 0.03,
                                        green: 0.14,
                                        blue: 0.27
                                    )
                                ),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var treeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isCompactLayout ? 8 : 10) {
                ForEach(skillTrees) { tree in
                    let isSelected = tree.id == skillTree?.id
                    let isUnlocked = isTreeUnlocked(tree.id)

                    Button {
                        if isUnlocked {
                            selectedTreeID = tree.id
                        }
                    } label: {
                        HStack(spacing: isCompactLayout ? 6 : 8) {
                            Image(
                                systemName: isUnlocked
                                    ? "point.3.connected.trianglepath.dotted"
                                    : "lock.fill"
                            )
                            .font(
                                .system(
                                    size: isCompactLayout ? 10 : 11,
                                    weight: .black
                                )
                            )
                            VStack(
                                alignment: .leading,
                                spacing: isCompactLayout ? 2 : 3
                            ) {
                                Text(tree.title)
                                    .font(
                                        .system(
                                            size: isCompactLayout ? 11 : 13,
                                            weight: .black
                                        )
                                    )
                                Text(
                                    isUnlocked
                                        ? tree.subtitle
                                        : unlockText(for: tree.id)
                                )
                                .font(
                                    .system(
                                        size: isCompactLayout ? 8 : 9,
                                        weight: .bold
                                    )
                                )
                                .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, isCompactLayout ? 10 : 14)
                        .padding(.vertical, isCompactLayout ? 8 : 10)
                        .frame(
                            minWidth: isCompactLayout ? 148 : 186,
                            alignment: .leading
                        )
                        .background(
                            isSelected && isUnlocked
                                ? LinearGradient(
                                    colors: [
                                        color(
                                            from: tree.palette?
                                                .selectorStartHex,
                                            fallback: Color.cyan.opacity(0.95)
                                        ),
                                        color(
                                            from: tree.palette?.selectorEndHex,
                                            fallback: Color.blue.opacity(0.75)
                                        ),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: isUnlocked
                                        ? [
                                            Color.black.opacity(0.42),
                                            Color.gray.opacity(0.28),
                                        ]
                                        : [
                                            Color.black.opacity(0.70),
                                            Color.black.opacity(0.52),
                                        ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            in: RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                            .stroke(
                                isSelected && isUnlocked
                                    ? .white.opacity(0.9)
                                    : .white.opacity(0.12),
                                lineWidth: isSelected && isUnlocked ? 2 : 1
                            )
                        )
                        .opacity(isUnlocked ? 1 : 0.72)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isUnlocked)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func content(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        VStack(spacing: isCompactLayout ? 10 : 16) {
            nodeCanvas(for: skillTree)
            autoUnlockPanel(for: skillTree)
        }
    }

    private func nodeCanvas(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack {
                ForEach(skillTree.nodes) { node in
                    if !node.prerequisites.isEmpty {
                        ForEach(node.prerequisites, id: \.self) {
                            prerequisite in
                            if let start = skillTree.nodes.first(where: {
                                $0.id == prerequisite
                            }) {
                                connection(
                                    from: start.position,
                                    to: node.position
                                )
                            }
                        }
                    }
                }

                ForEach(skillTree.nodes) { node in
                    skillNodeButton(node, in: skillTree)
                        .position(
                            scaledPoint(for: node.position)
                        )
                }
            }
            .frame(
                width: canvasSize.width,
                height: canvasSize.height
            )
            .padding(isCompactLayout ? 10 : 24)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: isCompactLayout ? 360 : 640
        )
        .background(
            LinearGradient(
                colors: [
                    color(
                        from: skillTree.palette?.panelStartHex,
                        fallback: Color.black.opacity(0.32)
                    ),
                    color(
                        from: skillTree.palette?.panelEndHex,
                        fallback: Color(red: 0.05, green: 0.11, blue: 0.22)
                            .opacity(0.92)
                    ),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func autoUnlockPanel(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        VStack(alignment: .leading, spacing: isCompactLayout ? 8 : 12) {
            Button {
                autoUnlockMessage = ""
                showsAutoUnlockConfirmation = true
            } label: {
                Text("Auto Unlock")
                    .font(
                        .system(
                            size: isCompactLayout ? 13 : 16,
                            weight: .black
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactLayout ? 10 : 14)
                    .background(
                        Color.black.opacity(0.30),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)

            Text(
                "Stage \(completedRanks(in: skillTree))/\(maximumRanks(in: skillTree)) Ranks"
            )
            .font(.system(size: isCompactLayout ? 10 : 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))

            if !autoUnlockMessage.isEmpty {
                Text(autoUnlockMessage)
                    .font(
                        .system(size: isCompactLayout ? 10 : 12, weight: .black)
                    )
                    .foregroundStyle(.orange)
            }
        }
        .padding(isCompactLayout ? 12 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    color(
                        from: skillTree.palette?.panelStartHex,
                        fallback: Color.black.opacity(0.32)
                    ),
                    color(
                        from: skillTree.palette?.panelEndHex,
                        fallback: Color(red: 0.05, green: 0.11, blue: 0.22)
                            .opacity(0.92)
                    ),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func skillNodeButton(
        _ node: CharacterSkillNodeDefinition,
        in skillTree: CharacterSkillTreeDefinition
    ) -> some View {
        let rank = nodeRanks[node.id] ?? 0
        let isSelected = selectedNodeID == node.id
        let isLearned = rank > 0
        let isMastered = rank >= node.maxRank
        let canLearn = PlayerInventoryStore.canLearnSkillNode(
            node,
            in: skillTree,
            characterID: character.model,
            in: modelContext
        )

        return Button {
            selectedNodeID = node.id
            presentedNodeID = node.id
        } label: {
            VStack(spacing: isCompactLayout ? 3 : 5) {
                ZStack(alignment: .topTrailing) {
                    nodeIcon(for: node, isLearned: isLearned)

                    if isLearned {
                        Image(
                            systemName: isMastered
                                ? "checkmark.seal.fill"
                                : "checkmark.circle.fill"
                        )
                        .font(
                            .system(
                                size: isCompactLayout ? 10 : 12,
                                weight: .black
                            )
                        )
                        .foregroundStyle(.white)
                        .padding(2)
                        .background(Color.black.opacity(0.42), in: Circle())
                        .offset(x: 8, y: -6)
                    }
                }

                Text(node.title)
                    .font(
                        .system(
                            size: isCompactLayout ? 9 : 11,
                            weight: .black
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(primaryBonusText(for: node))
                    .font(
                        .system(
                            size: isCompactLayout ? 8 : 9,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        isLearned ? .white.opacity(0.90) : .white.opacity(0.56)
                    )
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(rank)/\(node.maxRank)")
                    Text(
                        skillNodeStateText(
                            isLearned: isLearned,
                            isMastered: isMastered,
                            canLearn: canLearn
                        )
                    )
                }
                .font(
                    .system(
                        size: isCompactLayout ? 8 : 10,
                        weight: .black
                    )
                )
                .foregroundStyle(
                    isLearned ? .white : .white.opacity(canLearn ? 0.76 : 0.48)
                )
            }
            .foregroundStyle(isLearned ? .white : .white.opacity(0.62))
            .frame(width: nodeSize.width, height: nodeSize.height)
            .background(
                nodeBackgroundColor(
                    node: node,
                    rank: rank,
                    maxRank: node.maxRank,
                    canLearn: canLearn
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? color(
                                from: node.palette?.accentHex,
                                fallback: .yellow
                            )
                            : canLearn && !isLearned
                                ? .white.opacity(0.34)
                                : .white.opacity(isLearned ? 0.18 : 0.08),
                        lineWidth: isSelected || (canLearn && !isLearned)
                            ? 2 : 1
                    )
            )
            .opacity(isLearned ? 1 : canLearn ? 0.78 : 0.48)
        }
        .buttonStyle(.plain)
    }

    private func connection(
        from start: CharacterSkillNodePosition,
        to end: CharacterSkillNodePosition
    ) -> some View {
        Path { path in
            path.move(to: scaledPoint(for: start))
            path.addLine(to: scaledPoint(for: end))
        }
        .stroke(
            color(
                from: skillTree?.palette?.connectionHex,
                fallback: .white.opacity(0.18)
            ),
            style: StrokeStyle(
                lineWidth: isCompactLayout ? 2 : 3,
                lineCap: .round
            )
        )
    }

    private func scaledPoint(for position: CharacterSkillNodePosition)
        -> CGPoint
    {
        CGPoint(
            x: CGFloat(position.x) * canvasScale + (isCompactLayout ? 14 : 0),
            y: CGFloat(position.y) * canvasScale + (isCompactLayout ? 12 : 0)
        )
    }

    private var unavailableState: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.white.opacity(0.74))
            Text("Kein Skillbaum geladen")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
        }
    }

    private func nodeBackgroundColor(
        node: CharacterSkillNodeDefinition,
        rank: Int,
        maxRank: Int,
        canLearn: Bool
    ) -> LinearGradient {
        if rank > 0 && rank >= maxRank {
            return LinearGradient(
                colors: [
                    color(
                        from: node.palette?.masteredStartHex,
                        fallback: Color.green.opacity(0.85)
                    ),
                    color(
                        from: node.palette?.masteredEndHex,
                        fallback: Color.cyan.opacity(0.75)
                    ),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        if rank > 0 {
            return LinearGradient(
                colors: [
                    color(
                        from: node.palette?.fillStartHex,
                        fallback: Color.blue.opacity(0.90)
                    ),
                    color(
                        from: node.palette?.fillEndHex,
                        fallback: Color.teal.opacity(0.75)
                    ),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [
                Color.gray.opacity(canLearn ? 0.34 : 0.22),
                Color.black.opacity(canLearn ? 0.62 : 0.74),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private func currencyIcon(for currency: CurrencyDefinition) -> some View {
        if let assetIcon = currency.assetIcon,
            RemoteContentManager.hasCachedOrBundledImage(named: assetIcon)
        {
            RemoteAssetImage(assetIcon, contentMode: .fit) {
                Image(systemName: currency.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white)
            }
            .frame(width: 24, height: 24)
        } else {
            Image(systemName: currency.icon)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
        }
    }

    @ViewBuilder
    private func nodeIcon(
        for node: CharacterSkillNodeDefinition,
        isLearned: Bool
    ) -> some View {
        let accentColor =
            isLearned
            ? color(from: node.palette?.accentHex, fallback: .white)
            : .white.opacity(0.48)

        if let assetIcon = node.assetIcon,
            RemoteContentManager.hasCachedOrBundledImage(named: assetIcon)
        {
            RemoteAssetImage(assetIcon, contentMode: .fit) {
                Image(systemName: node.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(accentColor)
            }
            .frame(width: 32, height: 32)
        } else {
            Image(systemName: node.icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(accentColor)
        }
    }

    private func skillNodeStateText(
        isLearned: Bool,
        isMastered: Bool,
        canLearn: Bool
    ) -> String {
        if isMastered {
            return "MAX"
        }

        if isLearned {
            return "GELERNT"
        }

        return canLearn ? "LERNBAR" : "LOCK"
    }

    private func bonusLine(for bonus: CharacterSkillNodeBonus) -> String {
        let percent = Int((bonus.value * 100).rounded())
        let type = bonus.resolvedType

        if type.hasPrefix("stat_"), type.hasSuffix("_percent") {
            let statName =
                type
                .replacingOccurrences(of: "stat_", with: "")
                .replacingOccurrences(of: "_percent", with: "")
            return "+\(percent)% \(displayName(forBonusKey: statName))"
        }

        if type.hasPrefix("damage_"), type.hasSuffix("_percent") {
            let damageName =
                type
                .replacingOccurrences(of: "damage_", with: "")
                .replacingOccurrences(of: "_percent", with: "")
            let label =
                damageName == "cards"
                ? "Skill-DMG"
                : "\(displayName(forBonusKey: damageName)) DMG"
            return "+\(percent)% \(label)"
        }

        if type.hasPrefix("drop_"), type.hasSuffix("_percent") {
            let dropName =
                type
                .replacingOccurrences(of: "drop_", with: "")
                .replacingOccurrences(of: "_percent", with: "")
            return "+\(percent)% \(displayName(forBonusKey: dropName)) Drop"
        }

        if type.hasPrefix("resource_"), type.hasSuffix("_regen_percent") {
            let resourceName =
                type
                .replacingOccurrences(of: "resource_", with: "")
                .replacingOccurrences(of: "_regen_percent", with: "")
            return
                "+\(percent)% \(displayName(forBonusKey: resourceName)) Regen"
        }

        return "+\(percent)% \(displayName(forBonusKey: type))"
    }

    private func summaryLine(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("+\(Int((value * 100).rounded()))%")
                .fontWeight(.black)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.white.opacity(0.82))
    }

    private func currencyName(for code: String) -> String {
        gameState.currencies.first(where: { $0.code == code })?.name ?? code
    }

    private func primaryBonusText(for node: CharacterSkillNodeDefinition)
        -> String
    {
        node.bonuses.prefix(1).map(bonusLine).joined(separator: " ")
    }

    private func nodePopupSummary(for node: CharacterSkillNodeDefinition)
        -> String
    {
        let lines = node.bonuses.map(bonusLine).joined(separator: "\n")
        return
            "\(node.description)\n\n\(lines)\n\nKosten: \(node.costPerRank) \(currencyName(for: node.costCurrency))"
    }

    private var autoUnlockConfirmationText: String {
        guard let skillTree else {
            return "Kein Skillbaum aktiv."
        }

        return
            "Alle aktuell lernbaren Skills in \(skillTree.title) automatisch lernen?"
    }

    private func performAutoUnlock(in skillTree: CharacterSkillTreeDefinition) {
        let learnedCount = PlayerInventoryStore.autoLearnSkillNodes(
            in: skillTree,
            characterID: character.model,
            in: modelContext
        )

        if learnedCount > 0 {
            refreshID = UUID()
            autoUnlockMessage =
                "\(learnedCount) Skill-Rang\(learnedCount == 1 ? "" : "e") gelernt."
            return
        }

        autoUnlockMessage =
            hasResourceBlockedAutoUnlock(in: skillTree)
            ? "Zu wenig Ressourcen fuer Auto Unlock."
            : "Keine lernbaren Skills verfuegbar."
    }

    private func hasResourceBlockedAutoUnlock(
        in skillTree: CharacterSkillTreeDefinition
    ) -> Bool {
        let ranks = nodeRanks

        return skillTree.nodes.contains { node in
            let currentRank = ranks[node.id] ?? 0
            guard currentRank < node.maxRank else { return false }

            let prerequisitesMet = node.prerequisites.allSatisfy {
                (ranks[$0] ?? 0) > 0
            }
            guard prerequisitesMet else { return false }

            return PlayerInventoryStore.amount(
                for: node.costCurrency,
                in: modelContext
            ) < node.costPerRank
        }
    }

    private var firstAvailableTreeID: String? {
        skillTrees.first(where: { isTreeUnlocked($0.id) })?.id
            ?? skillTrees.first?.id
    }

    private func maximumRanks(in tree: CharacterSkillTreeDefinition) -> Int {
        tree.nodes.reduce(0) { $0 + $1.maxRank }
    }

    private func completedRanks(in tree: CharacterSkillTreeDefinition) -> Int {
        tree.nodes.reduce(0) { partialResult, node in
            partialResult + (nodeRanks[node.id] ?? 0)
        }
    }

    private func isTreeUnlocked(_ treeID: String) -> Bool {
        guard let index = skillTrees.firstIndex(where: { $0.id == treeID })
        else {
            return false
        }

        guard index > 0 else {
            return true
        }

        let previousTree = skillTrees[index - 1]
        return completedRanks(in: previousTree)
            >= maximumRanks(in: previousTree)
    }

    private func unlockText(for treeID: String) -> String {
        guard let index = skillTrees.firstIndex(where: { $0.id == treeID }),
            index > 0
        else {
            return "Freigeschaltet"
        }

        return "Maxe zuerst \(skillTrees[index - 1].title)"
    }

    private func nextLockedTree(after treeID: String)
        -> CharacterSkillTreeDefinition?
    {
        guard let index = skillTrees.firstIndex(where: { $0.id == treeID })
        else {
            return nil
        }

        return skillTrees.suffix(from: index + 1).first(where: {
            !isTreeUnlocked($0.id)
        })
    }

    private func color(from hex: String?, fallback: Color) -> Color {
        guard let hex else {
            return fallback
        }

        let sanitized =
            hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6 || sanitized.count == 8,
            let value = UInt64(sanitized, radix: 16)
        else {
            return fallback
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if sanitized.count == 8 {
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            alpha = Double(value & 0x0000_00FF) / 255
        } else {
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            alpha = 1
        }

        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    private func displayName(forBonusKey key: String) -> String {
        key
            .split(separator: "_")
            .map { part in
                part.prefix(1).uppercased() + part.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}
