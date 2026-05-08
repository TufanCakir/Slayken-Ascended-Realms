//
//  GameEventMapPreviewView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct GameEventMapPreviewView: View {
    let chapter: GlobeEventChapter?
    let point: GlobeEventPoint?
    let completedBattleIDs: Set<String>
    let selectedBattleID: String?
    let theme: GameTheme?
    let onSelectPoint: (GlobeEventPoint) -> Void
    let onSelectBattle: (GlobeBattle) -> Void

    @State private var countdownNow = Date()

    private var title: String {
        point?.title ?? chapter?.title ?? "World Map"
    }

    private var texture: String? {
        point?.mapTexture ?? chapter?.mapTexture
    }

    private var revealsBattlesSequentially: Bool {
        chapter?.isEventChapter != true
    }

    private var visibleBattles: [GlobeBattle] {
        guard let point else { return [] }
        return point.visibleBattles(
            completedBattleIDs: completedBattleIDs,
            revealsSequentially: revealsBattlesSequentially
        )
    }

    private var focusedNodeID: String? {
        if let point {
            if let selectedBattleID,
                visibleBattles.contains(where: { $0.id == selectedBattleID })
            {
                return "battle-\(selectedBattleID)"
            }

            if let nextBattle = point.nextUnlockedBattle(
                completedBattleIDs: completedBattleIDs,
                revealsSequentially: revealsBattlesSequentially
            ) {
                return nextBattle.mapNodeID
            }

            return nil
        }

        if let chapter {
            return chapter.nextPointWithIncompleteBattle(
                completedBattleIDs: completedBattleIDs
            ).map {
                $0.mapNodeID
            }
                ?? chapter.points.first.map {
                    $0.mapNodeID
                }
        }

        return nil
    }

    private var focusedNodePosition: EventMapNodePosition? {
        if let point {
            if let selectedBattleID,
                let selectedBattle = visibleBattles.first(where: {
                    $0.id == selectedBattleID
                })
            {
                return selectedBattle.node
            }

            if let nextBattle = point.nextUnlockedBattle(
                completedBattleIDs: completedBattleIDs,
                revealsSequentially: revealsBattlesSequentially
            ) {
                return nextBattle.node
            }

            return nil
        }

        if let chapter {
            return chapter.nextPointWithIncompleteBattle(
                completedBattleIDs: completedBattleIDs
            )?.node
                ?? chapter.points.first?.node
        }

        return nil
    }

    var body: some View {
        GeometryReader { geo in
            let viewportSize = geo.size
            let contentSize = resolvedContentSize(for: viewportSize)

            ZStack(alignment: .topLeading) {
                ScrollViewReader { proxy in
                    ScrollView(
                        [.horizontal, .vertical],
                        showsIndicators: false
                    ) {
                        ZStack(alignment: .topLeading) {
                            mapTexture(size: contentSize)

                            if point != nil {
                                routeLayer(
                                    nodes: visibleBattles.map(\.node),
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
                                        .id(battle.mapNodeID)
                                }
                            } else if let chapter {
                                routeLayer(
                                    nodes: chapter.points.map(\.node),
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
                                        .id(point.mapNodeID)
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

                previewHeader
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
        }
        .task {
            while !Task.isCancelled {
                countdownNow = .now
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let timingText = EventDateSupport.displayText(
                endsAt: chapter?.endsAt,
                now: countdownNow
            ) {
                Text(timingText)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(theme?.glow.color ?? .yellow)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.46), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private func resolvedContentSize(for viewportSize: CGSize) -> CGSize {
        if let texture,
            let image = RemoteContentManager.cachedOrBundledImage(
                named: texture
            )
        {
            return CGSize(
                width: max(image.size.width, viewportSize.width),
                height: max(image.size.height, viewportSize.height)
            )
        }

        return CGSize(
            width: max(viewportSize.width * 2.15, 980),
            height: max(viewportSize.height * 1.8, viewportSize.height)
        )
    }

    private func mapTexture(size: CGSize) -> some View {
        return ZStack {
            Color.black.opacity(0.08)

            if let texture {
                RemoteAssetImage(texture) {
                    Color.black.opacity(0.16)
                }
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

    private func routeLayer(nodes: [EventMapNodePosition], size: CGSize)
        -> some View
    {
        Path { path in
            guard let first = nodes.first else { return }
            path.move(to: mapPoint(first, in: size))
            for node in nodes.dropFirst() {
                path.addLine(to: mapPoint(node, in: size))
            }
        }
        .stroke(
            Color.white.opacity(0.73),
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
        let isFocused = point.mapNodeID == focusedNodeID

        return Button {
            onSelectPoint(point)
        } label: {
            VStack(spacing: 3) {
                nodeCircle(
                    imageName: point.resolvedNodeImage,
                    fallbackIcon: "mappin",
                    isCompleted: false,
                    isSelected: isFocused
                )

                Text(point.title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Color.black.opacity(isFocused ? 0.68 : 0.52),
                        in: Capsule()
                    )
                    .frame(width: 104)
            }
        }
        .buttonStyle(.plain)
    }

    private func battleDot(_ battle: GlobeBattle) -> some View {
        let isCompleted = completedBattleIDs.contains(battle.id)
        let isSelected =
            selectedBattleID == battle.id
            || battle.mapNodeID == focusedNodeID

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
            Ellipse()
                .fill(Color.black.opacity(0.30))
                .frame(
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 18 : 16
                )
                .offset(y: 16)

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
                .shadow(color: .black.opacity(0.24), radius: 2, y: 1)

            RemoteAssetImage(imageName) {
                Image(systemName: fallbackIcon)
                    .font(.system(size: isSelected ? 15 : 13, weight: .black))
                    .foregroundStyle(.black.opacity(0.72))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(.white.opacity(0.55), lineWidth: 1)
            )
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

    private func scrollToFocusedNode(with proxy: ScrollViewProxy) {
        guard let focusedNodeID, let focusedNodePosition else {
            return
        }

        let anchor = anchor(for: focusedNodePosition)

        Task { @MainActor in
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(45))
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(
                    focusedNodeID,
                    anchor: anchor
                )
            }
        }
    }

    private func anchor(for node: EventMapNodePosition) -> UnitPoint {
        UnitPoint(
            x: min(max(CGFloat(node.x), 0.18), 0.82),
            y: min(max(CGFloat(node.y), 0.22), 0.88)
        )
    }
}
