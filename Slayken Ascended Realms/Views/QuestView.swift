//
//  QuestView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI
import UIKit

struct QuestView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager

    @Query(sort: \PlayerQuestClaim.questID) private var claimedQuests:
        [PlayerQuestClaim]
    @Query(sort: \PlayerQuestCounter.key) private var questCounters:
        [PlayerQuestCounter]
    @Query(sort: \PlayerAccountProgress.id) private var accountProgress:
        [PlayerAccountProgress]
    let quests: [QuestDefinition]
    let onClose: () -> Void

    @State private var selectedCategory = "Alles"
    @State private var selectedChoiceCharacterByQuestID: [String: String] = [:]
    @State private var message = ""
    @State private var resourceRefreshDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    GameHeaderView(
                        currencies: gameState.currencies,
                        ascendedLevel: ascendedLevel
                    )
                    heroSection
                    farmLimitSection
                    categoryBar
                    questSections
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.45), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            _ = PlayerInventoryStore.dailyBattleFarmStatus(in: modelContext)
        }
        .task {
            while !Task.isCancelled {
                resourceRefreshDate = .now
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }

    private var ascendedLevel: Int {
        accountProgress.first?.level ?? 1
    }

    private var activeBattleFarmStatus: BattleResourceStatus {
        PlayerInventoryStore.dailyBattleFarmStatus(
            in: modelContext,
            now: resourceRefreshDate
        )
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quests")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text(
                "Schliesse Event- und Kampfziele ab, steige im Ascended Level und sichere dir kostenlose Rewards bis hin zu Charakter-Auswahlen."
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.82))

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var farmLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battle Energie und Limits")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                farmStatCard(
                    title: "Energie",
                    value: "\(activeBattleFarmStatus.energy)",
                    subtitle:
                        "Von \(activeBattleFarmStatus.energyMaximum), +\(activeBattleFarmStatus.energyRegenerationPerMinute)/Min",
                    assetName: nil,
                    systemName: "bolt.fill",
                    accent: .orange
                )

                farmStatCard(
                    title: "Coins",
                    value: "\(activeBattleFarmStatus.remainingCoins)",
                    subtitle:
                        "Von \(activeBattleFarmStatus.coinsLimitMaximum), +\(activeBattleFarmStatus.coinsRegenerationPerMinute)/Min",
                    assetName: "icon_coins",
                    systemName: "circle.hexagongrid.fill",
                    accent: .yellow
                )

                farmStatCard(
                    title: "Crystals",
                    value: "\(activeBattleFarmStatus.remainingCrystals)",
                    subtitle:
                        "Von \(activeBattleFarmStatus.crystalsLimitMaximum), +\(activeBattleFarmStatus.crystalsRegenerationPerMinute)/Min",
                    assetName: "icon_crystals",
                    systemName: "diamond.fill",
                    accent: .cyan
                )
            }

            Text(
                "Energie und Reward-Limits regenerieren automatisch jede Minute."
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.72))
        }
        .padding(16)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func farmStatCard(
        title: String,
        value: String,
        subtitle: String,
        assetName: String?,
        systemName: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let assetName, UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: systemName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(accent)
                }

                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }

            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var categories: [String] {
        ["Alles"] + Array(Set(quests.map(\.category))).sorted()
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(
                                selectedCategory == category ? .black : .white
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                    ? Color.yellow
                                    : Color.black.opacity(0.32),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredQuests: [QuestDefinition] {
        if selectedCategory == "Alles" {
            return quests
        }
        return quests.filter { $0.category == selectedCategory }
    }

    private var questSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(filteredQuests) { quest in
                questCard(quest)
            }
        }
    }

    private func questCard(_ quest: QuestDefinition) -> some View {
        let progress = progressValue(for: quest)
        let claimed = claimedQuests.contains { $0.questID == quest.id }
        let unlocked = ascendedLevel >= quest.requiredAscendedLevel
        let canClaim =
            unlocked && !claimed && progress >= quest.objective.target
        let selectedChoice = selectedChoiceCharacterByQuestID[quest.id]

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(quest.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)

                    Text(quest.subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))

                    Text(progressLabel(for: quest, progress: progress))
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(
                            canClaim ? .green : .cyan.opacity(0.92)
                        )
                }

                Spacer(minLength: 0)

                Image(
                    systemName: claimed
                        ? "checkmark.seal.fill"
                        : unlocked ? "flag.checkered.circle.fill" : "lock.fill"
                )
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(
                    claimed ? .green : unlocked ? .yellow : .white.opacity(0.56)
                )
            }

            progressBar(
                progress: min(
                    1,
                    CGFloat(progress) / CGFloat(max(1, quest.objective.target))
                )
            )

            rewardsPanel(for: quest)

            if !quest.choiceCharacterRewardIDs.isEmpty {
                choiceRewardStrip(for: quest)
            }

            if !unlocked {
                Text(
                    "Ab Ascended Level \(quest.requiredAscendedLevel) verfuegbar."
                )
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.orange)
            }

            Button {
                let didClaim = PlayerInventoryStore.claimQuest(
                    quest,
                    selectedCharacterID: selectedChoice,
                    in: modelContext
                )
                message =
                    didClaim
                    ? "\(quest.title) abgeschlossen."
                    : "Quest kann noch nicht beansprucht werden."
            } label: {
                Text(
                    claimed
                        ? "Bereits beansprucht"
                        : canClaim ? "Quest beanspruchen" : "Noch nicht bereit"
                )
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(
                    claimed ? .white.opacity(0.62) : canClaim ? .black : .white
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    claimed
                        ? Color.white.opacity(0.08)
                        : canClaim ? Color.yellow : Color.black.opacity(0.36),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(
                claimed || !canClaim
                    || (!quest.choiceCharacterRewardIDs.isEmpty
                        && selectedChoice == nil)
            )
        }
        .padding(16)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func progressBar(progress: CGFloat) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 10)
    }

    private func rewardsPanel(for quest: QuestDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rewards")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.74))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quest.rewards) { reward in
                        rewardChip(
                            title: currencyName(for: reward.currency),
                            subtitle: "+\(reward.amount)",
                            imageName: currencyAsset(for: reward.currency),
                            systemName: currencySymbol(for: reward.currency)
                        )
                    }

                    ForEach(quest.characterRewards, id: \.characterID) {
                        reward in
                        rewardChip(
                            title: characterName(for: reward.characterID),
                            subtitle: "Direkt",
                            imageName: characterPreview(
                                for: reward.characterID
                            ),
                            systemName: "person.crop.square"
                        )
                    }

                    if !quest.choiceCharacterRewardIDs.isEmpty {
                        rewardChip(
                            title: "Character Choice",
                            subtitle: "Waehle 1",
                            imageName: nil,
                            systemName: "person.3.sequence.fill"
                        )
                    }
                }
            }
        }
    }

    private func rewardChip(
        title: String,
        subtitle: String,
        imageName: String?,
        systemName: String
    ) -> some View {
        VStack(spacing: 6) {
            if let imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.yellow)
                    .frame(width: 34, height: 34)
            }

            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(width: 90, height: 92)
        .background(
            Color.white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    private func choiceRewardStrip(for quest: QuestDefinition) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waehle deinen Character")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.74))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quest.choiceCharacterRewardIDs, id: \.self) {
                        characterID in
                        let selected =
                            selectedChoiceCharacterByQuestID[quest.id]
                            == characterID

                        Button {
                            selectedChoiceCharacterByQuestID[quest.id] =
                                characterID
                        } label: {
                            VStack(spacing: 8) {
                                if let preview = characterPreview(
                                    for: characterID
                                ),
                                    UIImage(named: preview) != nil
                                {
                                    Image(preview)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 86, height: 86)
                                        .clipped()
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 16,
                                                style: .continuous
                                            )
                                        )
                                } else {
                                    Image(systemName: "person.crop.square")
                                        .font(.system(size: 30, weight: .black))
                                        .foregroundStyle(.yellow)
                                        .frame(width: 86, height: 86)
                                        .background(
                                            Color.white.opacity(0.06),
                                            in: RoundedRectangle(
                                                cornerRadius: 16,
                                                style: .continuous
                                            )
                                        )
                                }

                                Text(characterName(for: characterID))
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            .padding(8)
                            .background(
                                selected
                                    ? Color.yellow.opacity(0.20)
                                    : Color.white.opacity(0.04),
                                in: RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
                                .stroke(
                                    selected
                                        ? .yellow : .white.opacity(0.08),
                                    lineWidth: selected ? 2 : 1
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func progressValue(for quest: QuestDefinition) -> Int {
        switch quest.objective.type {
        case .ascendedLevel:
            return ascendedLevel
        case .battleVictories:
            return questCounterValue(for: "battle_victories")
        case .monsterKills:
            return questCounterValue(for: "monster_kills")
        case .currencyCollect:
            let currency = quest.objective.currency ?? "coins"
            return questCounterValue(for: "currency_earned_\(currency)")
        }
    }

    private func progressLabel(for quest: QuestDefinition, progress: Int)
        -> String
    {
        let current = min(progress, quest.objective.target)

        switch quest.objective.type {
        case .ascendedLevel:
            return "Ascended Level \(current)/\(quest.objective.target)"
        case .battleVictories:
            return "Kaempfe \(current)/\(quest.objective.target)"
        case .monsterKills:
            return "Monster \(current)/\(quest.objective.target)"
        case .currencyCollect:
            return
                "\(currencyName(for: quest.objective.currency ?? "coins")) \(current)/\(quest.objective.target)"
        }
    }

    private func questCounterValue(for key: String) -> Int {
        questCounters.first(where: { $0.key == key })?.value ?? 0
    }

    private func currencyName(for code: String) -> String {
        gameState.currencies.first(where: { $0.code == code })?.name ?? code
    }

    private func currencyAsset(for code: String) -> String? {
        gameState.currencies.first(where: { $0.code == code })?.assetIcon
    }

    private func currencySymbol(for code: String) -> String {
        gameState.currencies.first(where: { $0.code == code })?.icon
            ?? "circle.fill"
    }

    private func characterName(for characterID: String) -> String {
        gameState.summonCharacters.first(where: { $0.id == characterID })?.name
            ?? characterID
    }

    private func characterPreview(for characterID: String) -> String? {
        gameState.summonCharacters.first(where: { $0.id == characterID })?
            .summonImage
    }

    private var backgroundView: some View {
        ZStack {
            if let selectedTheme = theme.selectedTheme {
                Image(selectedTheme.background)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.74),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
