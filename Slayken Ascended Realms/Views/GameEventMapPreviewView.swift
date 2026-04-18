//
//  GameEventMapPreviewView.swift
//  Slayken Ascended Realms
//

import SwiftUI

struct GameEventMapPreviewView: View {
    let chapters: [GlobeEventChapter]
    let point: GlobeEventPoint?
    let completedBattleIDs: Set<String>
    let selectedBattleID: String?
    let theme: GameTheme?
    let onOpen: () -> Void
    let onSelectBattle: (GlobeBattle) -> Void

    @State private var selectedChapterID: String?
    @State private var isChapterDrawerExpanded = false

    private let mapHeight: CGFloat = 200

    private var selectedChapter: GlobeEventChapter? {
        chapters.first { $0.id == selectedChapterID } ?? chapters.first
    }

    private var title: String {
        point?.title ?? selectedChapter?.title ?? "Keine Kapitel"
    }

    private var texture: String? {
        point?.mapTexture ?? selectedChapter?.mapTexture
    }

    private var visibleBattles: [GlobeBattle] {
        guard let point else { return [] }
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

    private func chapterDrawer() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    isChapterDrawerExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(
                        systemName: isChapterDrawerExpanded
                            ? "chevron.up" : "chevron.down"
                    )
                    .font(.system(size: 10, weight: .black))

                    Text(selectedChapter?.title ?? "Kapitel")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if isChapterDrawerExpanded {
                VStack(spacing: 4) {
                    ForEach(chapters) { chapter in
                        Button {
                            selectedChapterID = chapter.id
                            isChapterDrawerExpanded = false
                        } label: {
                            Text(chapter.title)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(Color.black.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: isChapterDrawerExpanded ? 160 : 120)
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var body: some View {
        GeometryReader { geo in
            let viewportSize = CGSize(width: geo.size.width, height: mapHeight)
            let contentSize = CGSize(
                width: max(geo.size.width * 1.95, 840),
                height: mapHeight * 1.4  // 🔥 subtiler Scroll
            )

            ZStack(alignment: .topLeading) {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {

                            // 🔝 HEADER
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(
                                        point == nil
                                            ? "World Map" : "Battle Route"
                                    )
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.white.opacity(0.66))

                                    Text(title)
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    chapterDrawer()
                                        .padding(.top)
                                }

                                Spacer()

                                Button(action: onOpen) {
                                    Image(
                                        systemName:
                                            "arrow.up.left.and.arrow.down.right"
                                    )
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.black.opacity(0.74))
                                    .frame(width: 34, height: 34)
                                    .background(
                                        .white.opacity(0.92),
                                        in: Circle()
                                    )
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 10)

                            // 🔽 DRAWER DIREKT DARUNTER

                        }
                        .zIndex(10)
                        mapTexture(size: contentSize)

                        if let point {
                            battleRouteLayer(
                                battles: visibleBattles,
                                size: contentSize
                            )

                            ForEach(visibleBattles) { battle in
                                battleDot(battle, in: point)
                                    .position(
                                        mapPoint(battle.node, in: contentSize)
                                    )
                            }
                        } else if let chapter = selectedChapter {
                            pointRouteLayer(
                                points: chapter.points,
                                size: contentSize
                            )

                            ForEach(chapter.points) { point in
                                pointDot(point)
                                    .position(
                                        mapPoint(point.node, in: contentSize)
                                    )
                            }
                        }
                    }
                    .frame(width: contentSize.width, height: contentSize.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(width: viewportSize.width, height: viewportSize.height)
                .clipped()

                topFade(width: viewportSize.width)
                    .allowsHitTesting(false)
            }
        }
    }

    private func mapTexture(size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(0.04)

            if let texture {
                Image(texture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }

            Rectangle()
                .fill(Color.black.opacity(0.08))
        }
        .frame(width: size.width, height: size.height)
    }

    private func topFade(width: CGFloat) -> some View {
        LinearGradient(
            colors: [
                .black.opacity(0.72), .black.opacity(0.30), .black.opacity(0.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: width, height: 96)
    }

    private func pointRouteLayer(points: [GlobeEventPoint], size: CGSize)
        -> some View
    {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: mapPoint(first.node, in: size))
            for point in points.dropFirst() {
                path.addLine(to: mapPoint(point.node, in: size))
            }
        }
        .stroke(
            (theme?.glow.color ?? .white).opacity(0.80),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [8, 7]
            )
        )
        .shadow(color: .black.opacity(0.28), radius: 3, y: 1)
    }

    private func battleRouteLayer(battles: [GlobeBattle], size: CGSize)
        -> some View
    {
        Path { path in
            guard let first = battles.first else { return }
            path.move(to: mapPoint(first.node, in: size))
            for battle in battles.dropFirst() {
                path.addLine(to: mapPoint(battle.node, in: size))
            }
        }
        .stroke(
            (theme?.glow.color ?? .white).opacity(0.84),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [8, 7]
            )
        )
        .shadow(color: .black.opacity(0.28), radius: 3, y: 1)
    }

    private func pointDot(_ point: GlobeEventPoint) -> some View {
        VStack(spacing: 3) {
            nodeCircle(icon: "mappin", isCompleted: false, isSelected: false)

            Text(point.title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.46), in: Capsule())
                .frame(width: 96)
        }
    }

    private func battleDot(_ battle: GlobeBattle, in point: GlobeEventPoint)
        -> some View
    {
        let isCompleted = completedBattleIDs.contains(battle.id)
        let isSelected = selectedBattleID == battle.id

        return Button {
            onSelectBattle(battle)
        } label: {
            VStack(spacing: 3) {
                nodeCircle(
                    icon: isCompleted ? "checkmark" : "flame.fill",
                    isCompleted: isCompleted,
                    isSelected: isSelected
                )

                VStack(spacing: 1) {
                    Text(battle.name)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(isCompleted ? "Clear" : "Start")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Color.black.opacity(isSelected ? 0.66 : 0.46),
                    in: Capsule()
                )
                .frame(width: 104)
            }
        }
        .buttonStyle(.plain)
    }

    private func nodeCircle(icon: String, isCompleted: Bool, isSelected: Bool)
        -> some View
    {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.40))
                .frame(
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 52 : 44
                )
                .blur(radius: 6)
                .offset(y: 6)

            Circle()
                .fill(
                    isCompleted
                        ? Color.green.opacity(0.92)
                        : (theme?.glow.color ?? .yellow)
                )
                .frame(
                    width: isSelected ? 36 : 30,
                    height: isSelected ? 36 : 30
                )
                .overlay(
                    Circle().stroke(
                        .white.opacity(0.76),
                        lineWidth: isSelected ? 2 : 1
                    )
                )
                .shadow(color: .black.opacity(0.34), radius: 5, y: 2)

            Image(systemName: icon)
                .font(.system(size: isSelected ? 15 : 13, weight: .black))
                .foregroundStyle(.black.opacity(0.72))
        }
        .frame(width: 58, height: 50)
    }

    private func mapPoint(_ node: EventMapNodePosition, in size: CGSize)
        -> CGPoint
    {
        CGPoint(
            x: min(max(CGFloat(node.x), 0), 1) * size.width,
            y: min(max(CGFloat(node.y), 0), 1) * size.height
        )
    }
}

#Preview {
    let chapters = loadGlobeEventChapters()
    GameEventMapPreviewView(
        chapters: chapters,
        point: chapters.first?.points.first,
        completedBattleIDs: [],
        selectedBattleID: nil,
        theme: ThemeManager().selectedTheme,
        onOpen: {},
        onSelectBattle: { _ in }
    )
    .background(.black)
}
