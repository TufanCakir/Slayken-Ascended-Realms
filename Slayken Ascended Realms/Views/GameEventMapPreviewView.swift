//
//  GameEventMapPreviewView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct GameEventMapPreviewView: View {
    let chapter: GlobeEventChapter?
    let point: GlobeEventPoint?
    let completedBattleIDs: Set<String>
    let selectedBattleID: String?
    let theme: GameTheme?
    let onSelectPoint: (GlobeEventPoint) -> Void
    let onSelectBattle: (GlobeBattle) -> Void

    private var title: String {
        point?.title ?? chapter?.title ?? "World Map"
    }

    private var texture: String? {
        point?.mapTexture ?? chapter?.mapTexture
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

    private var focusedNodeID: String? {
        if point != nil, let selectedBattleID,
            visibleBattles.contains(where: { $0.id == selectedBattleID })
        {
            return nodeID(forBattleID: selectedBattleID)
        }

        if let point {
            return nextUnlockedBattle(in: point).map {
                nodeID(forBattleID: $0.id)
            }
                ?? nodeID(forPointID: point.id)
        }

        if let chapter {
            return nextUnlockedPoint(in: chapter).map {
                nodeID(forPointID: $0.id)
            }
                ?? nodeID(forPointID: chapter.points.first?.id ?? "")
        }

        return nil
    }

    var body: some View {
        GeometryReader { geo in
            let viewportSize = geo.size
            let contentSize = CGSize(
                width: max(geo.size.width * 2.15, 980),
                height: max(geo.size.height * 1.08, geo.size.height)
            )

            ZStack(alignment: .topLeading) {
                ScrollViewReader { proxy in
                    ScrollView(
                        [.horizontal, .vertical],
                        showsIndicators: false
                    ) {
                        ZStack(alignment: .topLeading) {
                            mapTexture(size: contentSize)

                            if point != nil {
                                battleRouteLayer(
                                    battles: visibleBattles,
                                    size: contentSize
                                )

                                ForEach(visibleBattles) { battle in
                                    battleDot(battle)
                                        .position(
                                            mapPoint(
                                                battle.node,
                                                in: contentSize
                                            )
                                        )
                                        .id(nodeID(forBattleID: battle.id))
                                }
                            } else if let chapter {
                                pointRouteLayer(
                                    points: chapter.points,
                                    size: contentSize
                                )

                                ForEach(chapter.points) { point in
                                    pointDot(point)
                                        .position(
                                            mapPoint(
                                                point.node,
                                                in: contentSize
                                            )
                                        )
                                        .id(nodeID(forPointID: point.id))
                                }
                            }
                        }
                        .frame(
                            width: contentSize.width,
                            height: contentSize.height
                        )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(
                        width: viewportSize.width,
                        height: viewportSize.height
                    )
                    .mask(topVanishMask(size: viewportSize))
                    .clipped()
                    .onAppear {
                        scrollToFocusedNode(with: proxy)
                    }
                    .onChange(of: focusedNodeID) { _, _ in
                        scrollToFocusedNode(with: proxy)
                    }
                }
            }
        }
    }

    private func mapTexture(size: CGSize) -> some View {
        return ZStack {
            Color.black.opacity(0.08)

            if let texture {
                Image(texture)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            }

        }
        .frame(width: size.width, height: size.height)
    }

    private func topVanishMask(size: CGSize) -> some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 0.10),
                .init(color: .black, location: 0.24),
                .init(color: .black, location: 0.42),
                .init(color: .black, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: size.width, height: size.height)
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
            Color.white.opacity(0.72),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [8, 7]
            )
        )
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
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
            Color.white.opacity(0.74),
            style: StrokeStyle(
                lineWidth: 3,
                lineCap: .round,
                lineJoin: .round,
                dash: [8, 7]
            )
        )
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }

    private func pointDot(_ point: GlobeEventPoint) -> some View {
        Button {
            onSelectPoint(point)
        } label: {
            VStack(spacing: 3) {
                nodeCircle(
                    imageName: point.resolvedNodeImage,
                    fallbackIcon: "mappin",
                    isCompleted: false,
                    isSelected: false
                )

                Text(point.title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.52), in: Capsule())
                    .frame(width: 104)
            }
        }
        .buttonStyle(.plain)
    }

    private func battleDot(_ battle: GlobeBattle) -> some View {
        let isCompleted = completedBattleIDs.contains(battle.id)
        let isSelected = selectedBattleID == battle.id

        return Button {
            onSelectBattle(battle)
        } label: {
            VStack(spacing: 3) {
                nodeCircle(
                    imageName: battle.resolvedNodeImage,
                    fallbackIcon: isCompleted ? "checkmark" : "flame.fill",
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
                    Color.black.opacity(isSelected ? 0.68 : 0.52),
                    in: Capsule()
                )
                .frame(width: 112)
            }
        }
        .buttonStyle(.plain)
    }

    private func nodeCircle(
        imageName: String,
        fallbackIcon: String,
        isCompleted: Bool,
        isSelected: Bool
    )
        -> some View
    {
        let size: CGFloat = isSelected ? 44 : 38

        return ZStack {
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
                        : (theme?.glow.color ?? .red)
                )
                .frame(
                    width: isSelected ? 38 : 32,
                    height: isSelected ? 38 : 32
                )
                .overlay(
                    Circle().stroke(
                        .white.opacity(0.76),
                        lineWidth: isSelected ? 2 : 1
                    )
                )
                .shadow(color: .black.opacity(0.34), radius: 5, y: 2)

            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(.white.opacity(0.55), lineWidth: 1)
                    )
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: isSelected ? 15 : 13, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))
            }
        }
        .frame(width: 60, height: 52)
    }

    private func mapPoint(_ node: EventMapNodePosition, in size: CGSize)
        -> CGPoint
    {
        CGPoint(
            x: min(max(CGFloat(node.x), 0), 1) * size.width,
            y: min(max(CGFloat(node.y), 0), 1) * size.height
        )
    }

    private func nextUnlockedBattle(in point: GlobeEventPoint) -> GlobeBattle? {
        visibleBattles.first { !completedBattleIDs.contains($0.id) }
            ?? visibleBattles.last
    }

    private func nextUnlockedPoint(in chapter: GlobeEventChapter)
        -> GlobeEventPoint?
    {
        chapter.points.first { point in
            point.battles.contains { !completedBattleIDs.contains($0.id) }
        }
    }

    private func scrollToFocusedNode(with proxy: ScrollViewProxy) {
        guard let focusedNodeID else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(
                    focusedNodeID,
                    anchor: UnitPoint(x: 0.5, y: 0.62)
                )
            }
        }
    }

    private func nodeID(forPointID id: String) -> String {
        "point-\(id)"
    }

    private func nodeID(forBattleID id: String) -> String {
        "battle-\(id)"
    }
}

#Preview {
    let chapters = loadGlobeEventChapters()
    GameEventMapPreviewView(
        chapter: chapters.first,
        point: chapters.first?.points.first,
        completedBattleIDs: [],
        selectedBattleID: nil,
        theme: ThemeManager().selectedTheme,
        onSelectPoint: { _ in },
        onSelectBattle: { _ in }
    )
    .background(.black)
}
