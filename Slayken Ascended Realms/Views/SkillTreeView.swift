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
        gameState.currencies.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        Group {
            if let skillTree {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        header(for: skillTree)
                        if showsTreeSelector {
                            treeSelector
                        }
                        currencyStrip(for: skillTree)
                        content(for: skillTree)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 52)
                    .padding(.bottom, 18)
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
    }

    private func header(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
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
                .frame(width: 38, height: 38)
                .background(Color.black.opacity(0.42), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func currencyStrip(for skillTree: CharacterSkillTreeDefinition)
        -> some View
    {
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(displayedCurrencies) { currency in
                    let amount =
                        balances.first { $0.code == currency.code }?.amount ?? 0

                    HStack(spacing: 8) {
                        currencyIcon(for: currency)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.78))
                            Text("\(amount)")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
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
            HStack(spacing: 10) {
                ForEach(skillTrees) { tree in
                    let isSelected = tree.id == skillTree?.id
                    let isUnlocked = isTreeUnlocked(tree.id)

                    Button {
                        if isUnlocked {
                            selectedTreeID = tree.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(
                                systemName: isUnlocked
                                    ? "point.3.connected.trianglepath.dotted"
                                    : "lock.fill"
                            )
                            .font(.system(size: 11, weight: .black))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tree.title)
                                    .font(.system(size: 13, weight: .black))
                                Text(
                                    isUnlocked
                                        ? tree.subtitle
                                        : unlockText(for: tree.id)
                                )
                                .font(.system(size: 9, weight: .bold))
                                .lineLimit(1)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minWidth: 186, alignment: .leading)
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
        VStack(spacing: 16) {
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
                            x: node.position.x,
                            y: node.position.y
                        )
                }
            }
            .frame(
                width: horizontalSizeClass == .compact ? 920 : 1100,
                height: 620
            )
            .padding(24)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: horizontalSizeClass == .compact ? 440 : 640
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
        VStack(alignment: .leading, spacing: 12) {
            Button {
                if PlayerInventoryStore.autoLearnSkillNodes(
                    in: skillTree,
                    characterID: character.model,
                    in: modelContext
                ) > 0 {
                    refreshID = UUID()
                }
            } label: {
                Text("Auto Unlock")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))
        }
        .padding(18)
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
            VStack(spacing: 5) {
                nodeIcon(for: node)
                Text(node.title)
                    .font(.system(size: 11, weight: .black))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(primaryBonusText(for: node))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(1)
                Text("\(rank)/\(node.maxRank)")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(.white)
            .frame(width: 132, height: 114)
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
                            : .white.opacity(0.12),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func connection(
        from start: CharacterSkillNodePosition,
        to end: CharacterSkillNodePosition
    ) -> some View {
        Path { path in
            path.move(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
        }
        .stroke(
            color(
                from: skillTree?.palette?.connectionHex,
                fallback: .white.opacity(0.18)
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
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
        if rank >= maxRank {
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

        if canLearn {
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
                color(
                    from: node.palette?.lockedStartHex,
                    fallback: Color.black.opacity(0.72)
                ),
                color(
                    from: node.palette?.lockedEndHex,
                    fallback: Color.gray.opacity(0.44)
                ),
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
    private func nodeIcon(for node: CharacterSkillNodeDefinition) -> some View {
        let accentColor = color(from: node.palette?.accentHex, fallback: .white)

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
