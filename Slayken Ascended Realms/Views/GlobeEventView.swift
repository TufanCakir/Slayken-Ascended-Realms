//
//  GlobeEventView.swift
//  Slayken Ascended Realms
//

import SceneKit
import SwiftUI

struct GlobeEventView: View {
    let maps: [GameMap]
    let selectedMap: GameMap
    let onSelect: (GameMap) -> Void

    @EnvironmentObject private var theme: ThemeManager
    @State private var focusedMapID: Int?
    @State private var expandedMarkerID: Int?

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    private var eventMaps: [GameMap] {
        var seenIDs = Set<Int>()
        return maps.filter { map in
            seenIDs.insert(map.id).inserted
        }
    }

    private var focusedMap: GameMap {
        eventMaps.first(where: { $0.id == focusedMapID }) ?? selectedMap
    }

    var body: some View {
        GeometryReader { geo in
            let globeFrame = globeFrame(in: geo.size)
            let currentTheme = activeTheme

            ZStack {
                backgroundGradient(for: currentTheme)
                    .ignoresSafeArea()

                GlobeSceneView(theme: currentTheme)
                    .frame(width: globeFrame.width, height: globeFrame.height)
                    .position(x: globeFrame.midX, y: globeFrame.midY)

                starField(theme: currentTheme)
                    .allowsHitTesting(false)

                ForEach(Array(eventMaps.enumerated()), id: \.element.id) {
                    index,
                    map in
                    eventMarker(
                        map: map,
                        index: index,
                        total: eventMaps.count,
                        globeFrame: globeFrame,
                        theme: currentTheme
                    )
                    .zIndex(focusedMap.id == map.id ? 2 : 1)
                }

                eventBanner(map: focusedMap, theme: currentTheme)
                    .padding(.horizontal, 16)
                    .padding(.top, 150)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .onAppear {
                focusedMapID = selectedMap.id
                expandedMarkerID = selectedMap.id
            }
            .onChange(of: selectedMap.id) { _, newValue in
                focusedMapID = newValue
                expandedMarkerID = newValue
            }
        }
    }

    private func backgroundGradient(for theme: GameTheme?) -> some View {
        LinearGradient(
            colors: [
                theme?.accent.color.opacity(0.92) ?? .black,
                .black,
                theme?.secondary.color.opacity(0.22) ?? .black.opacity(0.35),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func starField(theme: GameTheme?) -> some View {
        ZStack {

            ForEach(0..<32, id: \.self) { index in
                Circle()
                    .fill(
                        (theme?.glow.color ?? .white).opacity(
                            index % 3 == 0 ? 0.72 : 0.38
                        )
                    )
                    .frame(
                        width: index % 4 == 0 ? 2 : 1,
                        height: index % 4 == 0 ? 2 : 1
                    )
                    .position(starPosition(for: index))
            }
        }
    }

    private func eventBanner(map: GameMap, theme: GameTheme?) -> some View {
        HStack(spacing: 10) {
            Image(map.mapImage)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 58)
                .clipped()
                .overlay(
                    Rectangle()
                        .stroke(
                            (theme?.primary.color ?? .white).opacity(0.58),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Event")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            (theme?.secondary.color ?? .red).opacity(0.72),
                            in: Capsule()
                        )

                    Text("Lv. \(map.difficulty * 10)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme?.glow.color ?? .yellow)
                }

                Text(map.name)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(
                    map.story.first?.text
                        ?? "A new realm has appeared on the globe."
                )
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
            }

        }
        .padding(8)
        .background((theme?.accent.color ?? .black).opacity(0.42))
        .overlay(
            Rectangle()
                .stroke(
                    (theme?.primary.color ?? .white).opacity(0.22),
                    lineWidth: 1
                )
        )
    }

    private func eventMarker(
        map: GameMap,
        index: Int,
        total: Int,
        globeFrame: CGRect,
        theme: GameTheme?
    ) -> some View {
        let isFocused = focusedMap.id == map.id
        let isPanelExpanded = expandedMarkerID == map.id
        let point = eventPosition(for: index, total: total, in: globeFrame)
        let labelOffset = eventLabelOffset(
            for: point,
            in: globeFrame,
            isFocused: isFocused
        )

        return ZStack {
            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                    focusedMapID = map.id
                    expandedMarkerID = map.id
                }
            } label: {
                eventMarkerPin(isFocused: isFocused, theme: theme)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isFocused {
                eventMarkerPanel(
                    map: map,
                    theme: theme,
                    isExpanded: isPanelExpanded,
                    opensToLeading: labelOffset.width < 0
                )
                .offset(labelOffset)
            }
        }
        .frame(width: isFocused ? 190 : 48, height: isFocused ? 88 : 48)
        .position(point)
    }

    private func eventMarkerPanel(
        map: GameMap,
        theme: GameTheme?,
        isExpanded: Bool,
        opensToLeading: Bool
    ) -> some View {
        HStack(spacing: 6) {
            if opensToLeading {
                markerPanelContent(
                    map: map,
                    theme: theme,
                    isExpanded: isExpanded,
                    alignment: .trailing
                )
            }

            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                    expandedMarkerID = isExpanded ? nil : map.id
                }
            } label: {
                Image(
                    systemName: panelChevronName(
                        isExpanded: isExpanded,
                        opensToLeading: opensToLeading
                    )
                )
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black.opacity(0.72))
                .frame(width: 28, height: 38)
                .background(.white.opacity(0.92), in: Capsule())
                .shadow(color: .black.opacity(0.16), radius: 8, y: 2)
            }
            .buttonStyle(.plain)

            if !opensToLeading {
                markerPanelContent(
                    map: map,
                    theme: theme,
                    isExpanded: isExpanded,
                    alignment: .leading
                )
            }
        }
        .animation(
            .spring(response: 0.36, dampingFraction: 0.84),
            value: isExpanded
        )
    }

    private func markerPanelContent(
        map: GameMap,
        theme: GameTheme?,
        isExpanded: Bool,
        alignment: Alignment
    ) -> some View {
        let horizontalAlignment: HorizontalAlignment =
            alignment == .trailing ? .trailing : .leading

        return Button {
            onSelect(map)
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: horizontalAlignment, spacing: 3) {
                    Text(map.name)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .shadow(color: .black, radius: 2, y: 1)

                    HStack(spacing: 5) {
                        if alignment == .trailing {
                            Text("Start")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(theme?.glow.color ?? .yellow)
                        }

                        Text(eventSubtitle(for: map))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .shadow(color: .black, radius: 2, y: 1)

                        if alignment != .trailing {
                            Text("Start")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(theme?.glow.color ?? .yellow)
                        }
                    }
                }
                .frame(width: 130, alignment: alignment)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(width: isExpanded ? 150 : 0, alignment: alignment)
            .clipped()
            .background(
                (theme?.accent.color ?? .black).opacity(isExpanded ? 0.72 : 0)
                    .background(
                        isExpanded ? .ultraThinMaterial : .regularMaterial
                    )
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        (theme?.glow.color ?? .yellow).opacity(
                            isExpanded ? 0.75 : 0
                        )
                    )
                    .frame(height: 1)
            }
            .clipShape(Capsule())
            .opacity(isExpanded ? 1 : 0)
        }
        .buttonStyle(.plain)
        .disabled(!isExpanded)
    }

    private func panelChevronName(isExpanded: Bool, opensToLeading: Bool)
        -> String
    {
        if opensToLeading {
            return isExpanded ? "chevron.right" : "chevron.left"
        }
        return isExpanded ? "chevron.left" : "chevron.right"
    }

    private func eventMarkerPin(isFocused: Bool, theme: GameTheme?) -> some View
    {
        ZStack {
            Circle()
                .stroke(
                    (theme?.secondary.color ?? .red).opacity(
                        isFocused ? 0.48 : 0.22
                    ),
                    lineWidth: isFocused ? 2 : 1
                )
                .frame(width: isFocused ? 38 : 28, height: isFocused ? 38 : 28)
                .scaleEffect(isFocused ? 1.12 : 1)

            Circle()
                .fill((theme?.accent.color ?? .black).opacity(0.58))
                .frame(width: isFocused ? 24 : 20, height: isFocused ? 24 : 20)
                .overlay(
                    Circle()
                        .stroke(
                            (theme?.primary.color ?? .white).opacity(0.55),
                            lineWidth: 1
                        )
                )

            GlobeMarkerTriangle()
                .fill(
                    LinearGradient(
                        colors: [
                            theme?.glow.color ?? .yellow,
                            theme?.secondary.color ?? .red,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: isFocused ? 14 : 11, height: isFocused ? 13 : 10)
                .offset(y: isFocused ? 1 : 0)
        }
        .shadow(
            color: (theme?.glow.color ?? .red).opacity(isFocused ? 0.75 : 0.42),
            radius: isFocused ? 10 : 5
        )
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }

    private func eventSubtitle(for map: GameMap) -> String {
        "Difficulty \(map.difficulty) - \(map.enemy.name)"
    }

    private func globeFrame(in size: CGSize) -> CGRect {
        let diameter = min(size.width * 1.72, size.height * 0.62)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)

        return CGRect(
            x: center.x - diameter * 0.5,
            y: center.y - diameter * 0.5,
            width: diameter,
            height: diameter
        )
    }

    private func eventPosition(
        for index: Int,
        total: Int,
        in globeFrame: CGRect
    ) -> CGPoint {
        guard total > 1 else {
            return CGPoint(x: globeFrame.midX, y: globeFrame.midY)
        }

        let goldenAngle = CGFloat.pi * (3 - sqrt(5))
        let progress = (CGFloat(index) + 0.5) / CGFloat(total)
        let radius = sqrt(progress) * 0.49
        let angle = CGFloat(index) * goldenAngle - CGFloat.pi * 0.55
        let point = CGPoint(
            x: 0.5 + cos(angle) * radius * 0.96,
            y: 0.5 + sin(angle) * radius * 0.80
        )

        return CGPoint(
            x: globeFrame.minX + globeFrame.width * point.x,
            y: globeFrame.minY + globeFrame.height * point.y
        )
    }

    private func eventLabelOffset(
        for point: CGPoint,
        in globeFrame: CGRect,
        isFocused: Bool
    ) -> CGSize {
        let distance: CGFloat = isFocused ? 64 : 54
        let horizontal = point.x < globeFrame.midX ? distance : -distance
        let verticalDistance: CGFloat =
            abs(point.y - globeFrame.midY) < globeFrame.height * 0.12
            ? 0
            : (point.y < globeFrame.midY ? -24 : 24)

        return CGSize(width: horizontal, height: verticalDistance)
    }

    private func starPosition(for index: Int) -> CGPoint {
        let x = CGFloat((index * 37) % 100) / 100
        let y = CGFloat((index * 61) % 100) / 100

        return CGPoint(x: x * 900, y: y * 700)
    }
}

private struct GlobeMarkerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

private struct GlobeSceneView: UIViewRepresentable {
    let theme: GameTheme?

    func makeCoordinator() -> Coordinator {
        Coordinator(themeID: theme?.id)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = makeScene(theme: theme)
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.isPlaying = true
        view.preferredFramesPerSecond = 60
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.inertiaEnabled = true
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard context.coordinator.themeID != theme?.id else { return }
        context.coordinator.themeID = theme?.id
        uiView.scene = makeScene(theme: theme)
    }

    final class Coordinator {
        var themeID: Int?

        init(themeID: Int?) {
            self.themeID = themeID
        }
    }

    private func makeScene(theme: GameTheme?) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let globeNode = loadGlobeNode(theme: theme)
        globeNode.position = SCNVector3(0, 0, 0)
        globeNode.scale = SCNVector3(1.22, 1.22, 1.22)
        scene.rootNode.addChildNode(globeNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 34
        cameraNode.position = SCNVector3(0, 0, 3.7)
        scene.rootNode.addChildNode(cameraNode)

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1150
        keyLight.light?.color = theme?.primary.uiColor ?? UIColor.white
        keyLight.position = SCNVector3(-2.4, 2.8, 3.4)
        scene.rootNode.addChildNode(keyLight)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .ambient
        fillLight.light?.intensity = 320
        fillLight.light?.color =
            theme?.glow.uiColor.withAlphaComponent(0.65)
            ?? UIColor.systemBlue.withAlphaComponent(0.65)
        scene.rootNode.addChildNode(fillLight)

        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(0, 1, 0, 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        spin.duration = 70
        spin.repeatCount = .infinity
        globeNode.addAnimation(spin, forKey: "slowGlobeSpin")

        return scene
    }

    private func loadGlobeNode(theme: GameTheme?) -> SCNNode {
        let container = SCNNode()

        if let scene = SCNScene(named: "globe.usdz")
            ?? SCNScene(named: "3DModel/globe.usdz")
        {
            for child in scene.rootNode.childNodes {
                container.addChildNode(child.clone())
            }
        } else {
            let sphere = SCNSphere(radius: 1.35)
            sphere.firstMaterial?.diffuse.contents =
                theme?.secondary.uiColor ?? UIColor.systemBlue
            sphere.firstMaterial?.emission.contents =
                theme?.glow.uiColor.withAlphaComponent(0.28)
                ?? UIColor.systemTeal.withAlphaComponent(0.28)
            container.geometry = sphere
        }

        return container
    }
}

extension ColorData {
    fileprivate var uiColor: UIColor {
        UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

#Preview {
    GlobeEventView(
        maps: loadMaps(),
        selectedMap: loadMaps().first
            ?? GameMap(
                id: 0,
                name: "Preview Event",
                mapImage: "map1",
                difficulty: 1,
                enemy: CharacterStats(
                    name: "Dragon",
                    image: "acsended_riven",
                    model: "warriorin",
                    hp: 100,
                    attack: 10
                ),
                story: []
            ),
        onSelect: { _ in }
    )
    .environmentObject(ThemeManager())
}
