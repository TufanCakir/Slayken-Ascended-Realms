//
//  GlobeEventView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftData
import SwiftUI

struct GlobeEventView: View {
    let chapters: [GlobeEventChapter]
    let selectedBattleID: String?
    let onSelectBattle: (GlobeBattle) -> Void

    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var gameState: GameState
    @Query private var completedBattles: [PlayerBattleProgress]
    @State private var selectedChapterID: String?
    @State private var selectedPointID: String?
    @State private var activeCutscene: GlobeEventCutscene?
    @State private var battleAfterCutscene: GlobeBattle?
    @State private var isChapterDrawerExpanded = false

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var selectedChapter: GlobeEventChapter? {
        chapters.first { $0.id == selectedChapterID } ?? chapters.first
    }

    private var selectedPoint: GlobeEventPoint? {
        guard let selectedChapter, let selectedPointID else { return nil }
        return selectedChapter.points.first { $0.id == selectedPointID }
    }

    private var completedBattleIDs: Set<String> {
        Set(completedBattles.map(\.battleID))
    }

    var body: some View {
        GeometryReader { geo in
            let currentTheme = activeTheme

            ZStack {
                eventMapLayer(size: geo.size, theme: currentTheme)
                    .zIndex(0)

                mapEdgeFade()
                    .allowsHitTesting(false)
                    .zIndex(1)

                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            chapterDrawer(theme: currentTheme)

                            if selectedPoint != nil {
                                mapLevelButton(theme: currentTheme)
                            }
                        }
                        .padding(.leading, 12)
                        .padding(.top, 118)

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 0)

                    if selectedPoint != nil {
                        pointBattlePanel(theme: currentTheme)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 82)
                            .transition(
                                .move(edge: .bottom).combined(with: .opacity)
                            )
                    }
                }
                .zIndex(2)
            }
            .fullScreenCover(item: $activeCutscene) { cutscene in
                EventCutsceneView(cutscene: cutscene) {
                    finishCutscene()
                }
            }
            .onAppear {
                selectedChapterID =
                    gameState.activeEventChapterID ?? selectedChapterID
                    ?? chapters.first?.id
                restoreActivePointIfPossible()
            }
            .onChange(of: selectedChapterID) { _, _ in
                restoreActivePointIfPossible()
            }
        }
    }

    private func eventMapLayer(size: CGSize, theme: GameTheme?) -> some View {
        let canvasSize = mapCanvasSize(in: size)
        let texture =
            selectedPoint?.mapTexture ?? selectedChapter?.mapTexture ?? "map"

        return ZStack(alignment: .topLeading) {
            mapTexture(texture, size: canvasSize, theme: theme)

            if let selectedPoint {
                let battles = visibleBattles(for: selectedPoint)
                battleRouteLayer(
                    battles: battles,
                    canvasSize: canvasSize,
                    theme: theme
                )

                ForEach(battles) { battle in
                    battleMapNode(battle, canvasSize: canvasSize, theme: theme)
                }
            } else if let selectedChapter {
                pointRouteLayer(
                    points: selectedChapter.points,
                    canvasSize: canvasSize,
                    theme: theme
                )

                ForEach(selectedChapter.points) { point in
                    pointMapNode(point, canvasSize: canvasSize, theme: theme)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func mapTexture(
        _ imageName: String,
        size: CGSize,
        theme: GameTheme?
    ) -> some View {
        ZStack {
            Color.black

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            mapGrid(size: size, theme: theme)
                .opacity(0.16)
        }
        .frame(width: size.width, height: size.height)
    }

    private func mapEdgeFade() -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.54), .black.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 148)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [.black.opacity(0.0), .black.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        }
        .ignoresSafeArea()
    }

    private func mapGrid(size: CGSize, theme: GameTheme?) -> some View {
        Canvas { context, canvasSize in
            var path = Path()
            let step: CGFloat = 110
            var x: CGFloat = 0
            while x <= canvasSize.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                x += step
            }

            var y: CGFloat = 0
            while y <= canvasSize.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                y += step
            }

            context.stroke(
                path,
                with: .color((theme?.glow.color ?? .white).opacity(0.36)),
                lineWidth: 1
            )
        }
        .frame(width: size.width, height: size.height)
    }

    private func pointRouteLayer(
        points: [GlobeEventPoint],
        canvasSize: CGSize,
        theme: GameTheme?
    ) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: mapPoint(first.node, in: canvasSize))
            for point in points.dropFirst() {
                path.addLine(to: mapPoint(point.node, in: canvasSize))
            }
        }
        .stroke(
            LinearGradient(
                colors: [
                    theme?.glow.color ?? .yellow,
                    theme?.primary.color ?? .white,
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [10, 7]
            )
        )
    }

    private func battleRouteLayer(
        battles: [GlobeBattle],
        canvasSize: CGSize,
        theme: GameTheme?
    ) -> some View {
        Path { path in
            guard let first = battles.first else { return }
            path.move(to: mapPoint(first.node, in: canvasSize))
            for battle in battles.dropFirst() {
                path.addLine(to: mapPoint(battle.node, in: canvasSize))
            }
        }
        .stroke(
            LinearGradient(
                colors: [
                    theme?.secondary.color ?? .red,
                    theme?.glow.color ?? .yellow,
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [8, 6]
            )
        )
    }

    private func visibleBattles(for point: GlobeEventPoint) -> [GlobeBattle] {
        var result: [GlobeBattle] = []

        for index in point.battles.indices {
            let battle = point.battles[index]
            let isCompleted = completedBattleIDs.contains(battle.id)
            let previousCompleted =
                index == 0
                || completedBattleIDs.contains(point.battles[index - 1].id)

            if isCompleted || previousCompleted {
                result.append(battle)
            }
        }

        return result
    }

    private func pointMapNode(
        _ point: GlobeEventPoint,
        canvasSize: CGSize,
        theme: GameTheme?
    ) -> some View {
        let isFocused = selectedPointID == point.id
        let visibleCount = visibleBattles(for: point).count

        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedPointID = point.id
            }
            if let selectedChapter {
                gameState.selectEventPoint(point, in: selectedChapter)
            }
            playCutsceneIfAvailable(point.cutscene)
        } label: {
            mapNodeLabel(
                title: point.title,
                subtitle: "\(visibleCount)/\(point.battles.count) Kaempfe",
                icon: "map.fill",
                isFocused: isFocused,
                theme: theme
            )
        }
        .buttonStyle(.plain)
        .position(mapPoint(point.node, in: canvasSize))
        .zIndex(isFocused ? 5 : 3)
    }

    private func battleMapNode(
        _ battle: GlobeBattle,
        canvasSize: CGSize,
        theme: GameTheme?
    ) -> some View {
        let isFocused = selectedBattleID == battle.id

        return Button {
            if let cutscene = battle.cutscene {
                battleAfterCutscene = battle
                activeCutscene = cutscene
            } else {
                onSelectBattle(battle)
            }
        } label: {
            mapNodeLabel(
                title: battle.name,
                subtitle: "Lv. \(battle.difficulty * 10)",
                icon: "flame.fill",
                isFocused: isFocused,
                theme: theme
            )
        }
        .buttonStyle(.plain)
        .position(mapPoint(battle.node, in: canvasSize))
        .zIndex(isFocused ? 5 : 3)
    }

    private func mapNodeLabel(
        title: String,
        subtitle: String,
        icon: String,
        isFocused: Bool,
        theme: GameTheme?
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.44))
                    .frame(
                        width: isFocused ? 68 : 58,
                        height: isFocused ? 68 : 58
                    )
                    .offset(y: 10)
                    .blur(radius: 8)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme?.glow.color ?? .yellow,
                                theme?.primary.color.opacity(0.88)
                                    ?? .white.opacity(0.88),
                                theme?.accent.color.opacity(0.84)
                                    ?? .black.opacity(0.84),
                            ],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 34
                        )
                    )
                    .frame(
                        width: isFocused ? 54 : 46,
                        height: isFocused ? 54 : 46
                    )
                    .overlay(
                        Circle().stroke(
                            .white.opacity(0.72),
                            lineWidth: isFocused ? 2 : 1
                        )
                    )
                    .shadow(
                        color: (theme?.glow.color ?? .yellow).opacity(0.75),
                        radius: isFocused ? 18 : 10
                    )

                Image(systemName: icon)
                    .font(.system(size: isFocused ? 19 : 16, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))

                TrianglePointer()
                    .fill(theme?.glow.color ?? .yellow)
                    .frame(width: 16, height: 14)
                    .offset(y: isFocused ? 34 : 30)
                    .shadow(color: .black.opacity(0.36), radius: 3, y: 2)
            }
            .frame(width: 76, height: 76)

            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: isFocused ? 12 : 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: 118)
            .background(
                Color.black.opacity(isFocused ? 0.58 : 0.36),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(
                    .white.opacity(isFocused ? 0.34 : 0.14),
                    lineWidth: 1
                )
            )
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }

    private func chapterDrawer(theme: GameTheme?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    isChapterDrawerExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: isChapterDrawerExpanded
                            ? "chevron.up" : "chevron.down"
                    )
                    .font(.system(size: 11, weight: .black))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Kapitel")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white.opacity(0.66))
                        Text(selectedChapter?.title ?? "Auswahl")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isChapterDrawerExpanded {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(chapters) { chapter in
                            chapterButton(chapter, theme: theme)
                        }
                    }
                    .padding(.bottom, 2)
                }
                .frame(maxHeight: 280)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(width: isChapterDrawerExpanded ? 230 : 172, alignment: .leading)
        .background((theme?.accent.color ?? .black).opacity(0.28))
        .background(.ultraThinMaterial.opacity(0.58))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    (theme?.primary.color ?? .white).opacity(0.24),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func chapterButton(_ chapter: GlobeEventChapter, theme: GameTheme?)
        -> some View
    {
        let isSelected = selectedChapterID == chapter.id

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                selectedChapterID = chapter.id
                selectedPointID = nil
                isChapterDrawerExpanded = false
            }
            gameState.selectEventChapter(chapter)
            playCutsceneIfAvailable(chapter.cutscene)
        } label: {
            HStack(spacing: 8) {
                Image(
                    systemName: isSelected
                        ? "largecircle.fill.circle" : "circle"
                )
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(
                    isSelected
                        ? (theme?.glow.color ?? .yellow) : .white.opacity(0.55)
                )
                .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(chapter.subtitle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                    Text("\(chapter.points.count) Unterkapitel")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                (isSelected ? theme?.primary.color : theme?.accent.color)?
                    .opacity(isSelected ? 0.36 : 0.18)
                    ?? Color.black.opacity(0.24)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        .white.opacity(isSelected ? 0.38 : 0.12),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func mapLevelButton(theme: GameTheme?) -> some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                selectedPointID = nil
            }
            gameState.clearActiveEventPoint()
        } label: {
            Label("Kapitelkarte", systemImage: "arrow.uturn.left")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background((theme?.accent.color ?? .black).opacity(0.34))
                .background(.ultraThinMaterial.opacity(0.58))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func pointBattlePanel(theme: GameTheme?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let selectedPoint {
                let battles = visibleBattles(for: selectedPoint)
                HStack(spacing: 10) {
                    Image(selectedPoint.mapImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 46)
                        .clipped()
                        .overlay(
                            Rectangle().stroke(
                                .white.opacity(0.18),
                                lineWidth: 1
                            )
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedPoint.title)
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                        Text(selectedPoint.text)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(2)
                    }

                    Spacer()

                    Text(selectedPoint.mapTexture)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.46))
                        .lineLimit(1)
                }

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(battles) { battle in
                            battleButton(battle, theme: theme)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 190)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((theme?.accent.color ?? .black).opacity(0.28))
        .background(.ultraThinMaterial.opacity(0.55))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    (theme?.primary.color ?? .white).opacity(0.22),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func battleButton(_ battle: GlobeBattle, theme: GameTheme?)
        -> some View
    {
        Button {
            if let cutscene = battle.cutscene {
                battleAfterCutscene = battle
                activeCutscene = cutscene
            } else {
                onSelectBattle(battle)
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Lv. \(battle.difficulty * 10)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(theme?.glow.color ?? .yellow)
                        Text(battle.name)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Text(battle.description)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)

                    Text(
                        "Ground: \(battle.groundTexture)  Sky: \(battle.skyboxTexture)"
                    )
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    ForEach(battle.rewards) { reward in
                        Text("+\(reward.amount) \(reward.currency)")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))
                    .frame(width: 30, height: 30)
                    .background(
                        (theme?.glow.color ?? .yellow).opacity(0.92),
                        in: Circle()
                    )
            }
            .padding(9)
            .background(
                Color.black.opacity(selectedBattleID == battle.id ? 0.62 : 0.30)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        selectedBattleID == battle.id
                            ? (theme?.glow.color ?? .yellow)
                            : .white.opacity(0.14),
                        lineWidth: selectedBattleID == battle.id ? 2 : 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func mapCanvasSize(in size: CGSize) -> CGSize {
        size
    }

    private func mapPoint(_ node: EventMapNodePosition, in size: CGSize)
        -> CGPoint
    {
        CGPoint(
            x: min(max(CGFloat(node.x), 0), 1) * size.width,
            y: min(max(CGFloat(node.y), 0), 1) * size.height
        )
    }

    private func playCutsceneIfAvailable(_ cutscene: GlobeEventCutscene?) {
        guard let cutscene else { return }
        battleAfterCutscene = nil
        activeCutscene = cutscene
    }

    private func restoreActivePointIfPossible() {
        guard
            let selectedChapterID,
            let activePointID = gameState.activeEventPointID,
            chapters.first(where: { $0.id == selectedChapterID })?.points
                .contains(where: { $0.id == activePointID }) == true
        else {
            selectedPointID = nil
            return
        }

        selectedPointID = activePointID
    }

    private func finishCutscene() {
        let pendingBattle = battleAfterCutscene
        activeCutscene = nil
        battleAfterCutscene = nil

        if let pendingBattle {
            onSelectBattle(pendingBattle)
        }
    }
}

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

#Preview {
    GlobeEventView(
        chapters: loadGlobeEventChapters(),
        selectedBattleID: nil
    ) { _ in }
    .environmentObject(ThemeManager())
    .environmentObject(GameState())
}
