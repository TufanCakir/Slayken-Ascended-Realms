//
//  GameSceneView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SceneKit
import SwiftUI
import UIKit

private enum GameSceneNodeCache {
    nonisolated(unsafe) static let modelCache = NSCache<NSString, SCNNode>()
}

struct GameSceneView: UIViewRepresentable {
    @EnvironmentObject private var performanceMode: PerformanceModeManager

    let player: CharacterStats
    let joystickVector: SIMD2<Float>
    let autoMoveTarget: SIMD2<Float>?
    let groundTexture: String
    let skyboxTexture: String
    let previewTransform: CharacterPreviewTransform?
    let onAutoMoveFinished: () -> Void

    init(
        player: CharacterStats,
        joystickVector: SIMD2<Float>,
        autoMoveTarget: SIMD2<Float>?,
        groundTexture: String,
        skyboxTexture: String,
        previewTransform: CharacterPreviewTransform? = nil,
        onAutoMoveFinished: @escaping () -> Void = {}
    ) {
        self.player = player
        self.joystickVector = joystickVector
        self.autoMoveTarget = autoMoveTarget
        self.groundTexture = groundTexture
        self.skyboxTexture = skyboxTexture
        self.previewTransform = previewTransform
        self.onAutoMoveFinished = onAutoMoveFinished
    }

    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator(
            player: player,
            previewTransform: previewTransform ?? .identity
        )
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = context.coordinator.scene
        view.backgroundColor = .black
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.isPlaying = true
        view.preferredFramesPerSecond = performanceMode.sceneFramesPerSecond
        view.antialiasingMode =
            performanceMode.isReducedEffectsEnabled ? .none : .multisampling2X

        context.coordinator.updatePerformanceMode(
            reducedEffects: performanceMode.isReducedEffectsEnabled
        )
        context.coordinator.start()
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.preferredFramesPerSecond = performanceMode.sceneFramesPerSecond
        uiView.antialiasingMode =
            performanceMode.isReducedEffectsEnabled ? .none : .multisampling2X
        context.coordinator.updatePerformanceMode(
            reducedEffects: performanceMode.isReducedEffectsEnabled
        )
        context.coordinator.joystickVector = joystickVector
        context.coordinator.autoMoveTarget = autoMoveTarget
        context.coordinator.onAutoMoveFinished = onAutoMoveFinished
        context.coordinator.updateTextures(
            ground: groundTexture,
            skybox: skyboxTexture
        )
    }
}

final class SceneCoordinator {
    let scene = SCNScene()
    private let groundBaseDepth: CGFloat = 100
    private let groundThickness: CGFloat = 6
    private let player: CharacterStats
    private let previewTransform: CharacterPreviewTransform

    private let playerNode = SCNNode()
    private let playerVisualNode = SCNNode()
    private let cameraNode = SCNNode()
    private var groundNode: SCNNode?
    private var groundBox: SCNBox?

    private var currentGroundTexture = TextureNames.ground
    private var currentSkyboxTexture = TextureNames.skybox
    private var appliedGroundTexture = ""
    private var appliedSkyboxTexture = ""

    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var isReducedEffectsEnabled = false

    var joystickVector: SIMD2<Float> = .zero
    var autoMoveTarget: SIMD2<Float>?
    var onAutoMoveFinished: () -> Void = {}

    init(
        player: CharacterStats,
        previewTransform: CharacterPreviewTransform = .identity
    ) {
        self.player = player
        self.previewTransform = previewTransform
    }

    func start() {
        guard displayLink == nil else { return }

        setupScene()

        let link = CADisplayLink(
            target: self,
            selector: #selector(stepFrame(_:))
        )
        link.preferredFramesPerSecond = isReducedEffectsEnabled ? 30 : 60
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    deinit {
        displayLink?.invalidate()
    }

    func updatePerformanceMode(reducedEffects: Bool) {
        guard isReducedEffectsEnabled != reducedEffects else { return }
        isReducedEffectsEnabled = reducedEffects
        displayLink?.preferredFramesPerSecond = reducedEffects ? 30 : 60
        scene.rootNode.enumerateChildNodes { node, _ in
            guard let light = node.light, light.type == .directional else {
                return
            }
            light.castsShadow = !reducedEffects
            light.shadowSampleCount = reducedEffects ? 1 : 6
            light.shadowRadius = reducedEffects ? 1 : 3
        }
    }

    private func setupScene() {
        guard scene.rootNode.childNodes.isEmpty else { return }

        scene.rootNode.addChildNode(makeCamera())
        scene.rootNode.addChildNode(makeLights())
        scene.rootNode.addChildNode(makeGround())
        scene.rootNode.addChildNode(makePlayer())

        let initialSkybox = RemoteContentManager.cachedOrBundledImage(
            named: "bg_sar"
        )
        scene.background.contents = initialSkybox
        scene.lightingEnvironment.contents = initialSkybox
    }

    func updateTextures(ground: String, skybox: String) {
        if currentGroundTexture != ground {
            currentGroundTexture = ground
        }

        if currentSkyboxTexture != skybox {
            currentSkyboxTexture = skybox
        }

        if appliedGroundTexture != currentGroundTexture {
            applyGroundTexture(named: currentGroundTexture)
            appliedGroundTexture = currentGroundTexture
        }

        if appliedSkyboxTexture != currentSkyboxTexture {
            let skyboxImage = RemoteContentManager.cachedOrBundledImage(
                named: currentSkyboxTexture
            )
            scene.background.contents = skyboxImage
            scene.lightingEnvironment.contents = skyboxImage
            appliedSkyboxTexture = currentSkyboxTexture
        }
    }

    private func makeCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 70  // 100 ist zu viel (verzerrt)

        cameraNode.camera = camera

        // 🔥 Startposition (wichtig!)
        cameraNode.position = SCNVector3(0, 25, 45)
        cameraNode.eulerAngles = SCNVector3(-atan2f(25, 45), 0, 0)

        return cameraNode
    }

    private func makeGround() -> SCNNode {
        let box = SCNBox(
            width: groundBaseDepth,
            height: groundThickness,
            length: groundBaseDepth,
            chamferRadius: 1.2
        )
        box.widthSegmentCount = 12
        box.lengthSegmentCount = 12
        box.heightSegmentCount = 2
        box.materials = makeGroundMaterials()

        let node = SCNNode(geometry: box)
        node.position.y = -Float(groundThickness) * 0.5
        node.castsShadow = true

        groundBox = box
        groundNode = node

        return node
    }

    private var groundMaterials: [SCNMaterial] = []

    private func makeGroundMaterials() -> [SCNMaterial] {
        let sideMaterial = SCNMaterial()
        sideMaterial.lightingModel = .physicallyBased
        sideMaterial.diffuse.contents = UIColor(
            red: 0.18,
            green: 0.15,
            blue: 0.13,
            alpha: 1
        )
        sideMaterial.roughness.contents = 0.95
        sideMaterial.metalness.contents = 0.0

        let topMaterial = SCNMaterial()
        topMaterial.isDoubleSided = false
        topMaterial.lightingModel = .physicallyBased
        topMaterial.diffuse.wrapS = .clamp
        topMaterial.diffuse.wrapT = .clamp
        topMaterial.diffuse.minificationFilter = .linear
        topMaterial.diffuse.magnificationFilter = .linear
        topMaterial.diffuse.mipFilter = .linear
        topMaterial.roughness.contents = 1.0
        topMaterial.metalness.contents = 0.0

        configureGroundMaterial(topMaterial, textureName: currentGroundTexture)
        groundMaterials = [topMaterial]

        return [
            sideMaterial,
            sideMaterial,
            sideMaterial,
            sideMaterial,
            topMaterial,
            sideMaterial,
        ]
    }

    private func applyGroundTexture(named textureName: String) {
        for material in groundMaterials {
            configureGroundMaterial(material, textureName: textureName)
        }
    }

    private func configureGroundMaterial(
        _ material: SCNMaterial,
        textureName: String
    ) {
        guard
            let image = RemoteContentManager.cachedOrBundledImage(
                named: textureName
            )
        else {
            material.diffuse.contents = nil
            if let box = groundBox {
                box.width = groundBaseDepth
                box.length = groundBaseDepth
            }
            return
        }

        material.diffuse.contents = image
        material.diffuse.wrapS = .repeat

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        if let box = groundBox {
            box.length = groundBaseDepth
        }
    }

    private func makeLights() -> SCNNode {
        let rig = SCNNode()

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 900
        ambient.color = UIColor(white: 0.9, alpha: 1)

        let ambientNode = SCNNode()
        ambientNode.light = ambient
        rig.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 1200
        directional.color = UIColor.white
        directional.castsShadow = !isReducedEffectsEnabled
        directional.shadowMode = .modulated
        directional.shadowRadius = isReducedEffectsEnabled ? 1 : 3
        directional.shadowSampleCount = isReducedEffectsEnabled ? 1 : 6
        directional.shadowColor = UIColor.black.withAlphaComponent(0.35)

        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-0.8, 0.5, 0)
        rig.addChildNode(directionalNode)

        return rig
    }

    private var currentAnimation: String = ""
    private let playerHeightOffset: Float = 1

    private struct PlayerAnimation {
        let node: SCNNode
        let key: String
        let animation: SCNAnimation
    }

    private func playAnimation(named name: String) {
        guard currentAnimation != name else { return }
        currentAnimation = name

        stopStoredAnimations()

        guard !animations.isEmpty else {
            return
        }

        for entry in animations {
            let animationPlayer = SCNAnimationPlayer(animation: entry.animation)
            entry.node.addAnimationPlayer(animationPlayer, forKey: entry.key)
            animationPlayer.play()
        }
    }

    private func stopPlayerAnimation() {
        guard !currentAnimation.isEmpty else { return }
        currentAnimation = ""
        stopStoredAnimations()
    }

    private func stopStoredAnimations() {
        for entry in animations {
            entry.node.removeAnimation(
                forKey: entry.key,
                blendOutDuration: 0.15
            )
        }
        playerNode.removeAllAnimations()
        playerVisualNode.removeAllAnimations()
    }

    private func getGroundTopY() -> Float {
        guard let ground = groundNode,
            let box = ground.geometry as? SCNBox
        else { return 0 }
        return ground.position.y + Float(box.height) * 0.5
    }

    private func makePlayer() -> SCNNode {
        // 1. Model laden
        if let cachedModelNode = makePreparedModelNode(
            modelName: player.model,
            player: player
        ) {
            playerVisualNode.addChildNode(cachedModelNode)
        }

        // 2. Z-UP → Y-UP Rotation ZUERST!

        // 3. Jetzt korrekte BoundingBox holen
        let bounds = playerVisualNode.boundingBox

        // 4. Pivot auf Füße setzen (BOTTOM CENTER)
        let centerX = (bounds.min.x + bounds.max.x) * 0.5
        let centerZ = (bounds.min.z + bounds.max.z) * 0.5

        playerVisualNode.pivot = SCNMatrix4MakeTranslation(
            centerX,
            bounds.min.y,
            centerZ
        )

        // 5. Skalierung (nach Pivot!)
        let height = max(bounds.max.y - bounds.min.y, 0.01)
        let scale = 10 / height

        let previewScale = Float(previewTransform.scaleMultiplier ?? 1)
        let resolvedScale = scale * previewScale
        playerVisualNode.scale = SCNVector3(
            resolvedScale,
            resolvedScale,
            resolvedScale
        )

        playerVisualNode.eulerAngles = SCNVector3(
            Float((previewTransform.pitchDegrees ?? 0) * .pi / 180),
            Float((previewTransform.yawDegrees ?? 0) * .pi / 180),
            Float((previewTransform.rollDegrees ?? 0) * .pi / 180)
        )

        addSkinSceneEffects(
            for: player,
            to: playerVisualNode,
            bounds: bounds
        )

        // 6. In Parent einhängen
        playerNode.addChildNode(playerVisualNode)

        // 7. EXAKT auf Boden setzen
        playerNode.position = SCNVector3(
            0,
            getGroundTopY() + playerHeightOffset
                + Float(previewTransform.verticalOffset ?? 0),
            0
        )

        loadAnimations()

        return playerNode
    }

    private func makePreparedModelNode(modelName: String, player: CharacterStats)
        -> SCNNode?
    {
        let cacheKey = skinCacheKey(modelName: modelName, player: player)
        if let cachedNode = GameSceneNodeCache.modelCache.object(
            forKey: cacheKey
        ) {
            return cachedNode.clone()
        }

        guard let modelScene = loadModelScene(named: modelName) else {
            return nil
        }

        let prototypeNode = SCNNode()
        for child in modelScene.rootNode.childNodes {
            prototypeNode.addChildNode(child.clone())
        }
        applyCharacterMaterial(player, to: prototypeNode)
        GameSceneNodeCache.modelCache.setObject(prototypeNode, forKey: cacheKey)
        return prototypeNode.clone()
    }

    private func skinCacheKey(modelName: String, player: CharacterStats)
        -> NSString
    {
        [
            modelName,
            player.texture ?? "-",
            player.materialColor ?? "-",
            player.emissionColor ?? "-",
            String(player.emissionIntensity ?? -1),
            String(player.roughness ?? -1),
            String(player.metalness ?? -1),
        ]
        .joined(separator: "|") as NSString
    }

    private func loadModelScene(named modelName: String) -> SCNScene? {
        let candidateNames = [
            "\(modelName).usdz",
            "3DClass/\(modelName).usdz",
            "3DClassAnimation/\(modelName).usdz",
            "3DHeroClasses/\(modelName).usdz",
            "3DHeroClassesAnimation/\(modelName).usdz",
            "3DModel/\(modelName).usdz",
            "3DModelleAnimation/\(modelName).usdz",
            "3DMonster/\(modelName).usdz",
            "\(modelName).scn",
            "3DClass/\(modelName).scn",
            "3DClassAnimation/\(modelName).scn",
            "3DHeroClasses/\(modelName).scn",
            "3DHeroClassesAnimation/\(modelName).scn",
            "3DModel/\(modelName).scn",
            "3DModelleAnimation/\(modelName).scn",
            "3DMonster/\(modelName).scn",
        ]

        if let remoteScene = RemoteContentManager.cachedScene(
            candidateNames: candidateNames
        ) {
            return remoteScene
        }

        return nil
    }

    private func applyCharacterMaterial(
        _ player: CharacterStats,
        to rootNode: SCNNode
    ) {
        let image =
            player.texture.flatMap { textureName in
                textureName.isEmpty ? nil : loadTextureImage(named: textureName)
            }
        let materialColor = color(from: player.materialColor)
        let emissionColor = color(from: player.emissionColor)
        guard
            image != nil || materialColor != nil || emissionColor != nil
                || player.roughness != nil || player.metalness != nil
        else { return }

        rootNode.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }

            let copiedGeometry = geometry.copy() as? SCNGeometry ?? geometry
            let copiedMaterials =
                copiedGeometry.materials.isEmpty
                ? [SCNMaterial()]
                : copiedGeometry.materials.map { material in
                    material.copy() as? SCNMaterial ?? material
                }

            for material in copiedMaterials {
                material.lightingModel = .physicallyBased
                if let image {
                    material.diffuse.contents = image
                    material.multiply.contents = materialColor
                } else if let materialColor {
                    material.diffuse.contents = materialColor
                }
                material.diffuse.wrapS = .repeat
                material.diffuse.wrapT = .repeat
                material.emission.contents = emissionColor
                if let emissionIntensity = player.emissionIntensity {
                    material.emission.intensity = CGFloat(emissionIntensity)
                }
                material.roughness.contents = player.roughness ?? 0.85
                material.metalness.contents = player.metalness ?? 0.0
                material.isDoubleSided = true
            }

            copiedGeometry.materials = copiedMaterials
            node.geometry = copiedGeometry
        }
    }

    private func addSkinSceneEffects(
        for player: CharacterStats,
        to rootNode: SCNNode,
        bounds: (min: SCNVector3, max: SCNVector3)
    ) {
        guard !isReducedEffectsEnabled else { return }

        let width = max(bounds.max.x - bounds.min.x, 0.1)
        let depth = max(bounds.max.z - bounds.min.z, 0.1)
        let height = max(bounds.max.y - bounds.min.y, 0.1)
        let radius =
            CGFloat(max(width, depth)) * CGFloat(player.auraRadius ?? 0.62)

        if let auraColor = color(from: player.auraColor) {
            let aura = SCNNode(
                geometry: SCNTorus(
                    ringRadius: radius,
                    pipeRadius: max(0.015, radius * 0.035)
                )
            )
            aura.geometry?.firstMaterial?.diffuse.contents =
                auraColor.withAlphaComponent(0.65)
            aura.geometry?.firstMaterial?.emission.contents = auraColor
            aura.geometry?.firstMaterial?.emission.intensity =
                CGFloat(player.auraIntensity ?? 1.0)
            aura.position = SCNVector3(0, bounds.min.y + 0.08, 0)
            aura.eulerAngles.x = Float.pi / 2
            aura.opacity = 0.72
            rootNode.addChildNode(aura)
        }

        if let shadowColor = color(from: player.shadowColor) {
            let shadow = SCNNode(
                geometry: SCNCylinder(
                    radius: radius * 0.95,
                    height: 0.012
                )
            )
            shadow.geometry?.firstMaterial?.diffuse.contents =
                shadowColor.withAlphaComponent(CGFloat(player.shadowOpacity ?? 0.32))
            shadow.geometry?.firstMaterial?.isDoubleSided = true
            shadow.position = SCNVector3(0, bounds.min.y + 0.02, 0)
            rootNode.addChildNode(shadow)
        }

        if player.particleEffect != nil {
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 80
            particleSystem.particleLifeSpan = 1.0
            particleSystem.particleLifeSpanVariation = 0.35
            particleSystem.particleSize = 0.08
            particleSystem.particleSizeVariation = 0.04
            particleSystem.spreadingAngle = 140
            particleSystem.emitterShape = SCNSphere(radius: radius * 0.65)
            particleSystem.particleColor =
                color(from: player.auraColor)
                ?? color(from: player.emissionColor)
                ?? UIColor.cyan
            particleSystem.isLocal = true

            let particleNode = SCNNode()
            particleNode.position = SCNVector3(
                0,
                bounds.min.y + height * 0.55,
                0
            )
            particleNode.addParticleSystem(particleSystem)
            rootNode.addChildNode(particleNode)
        }
    }

    private func color(from hex: String?) -> UIColor? {
        guard let hex else { return nil }
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard let value = UInt64(trimmed, radix: 16) else { return nil }

        switch trimmed.count {
        case 6:
            return UIColor(
                red: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1
            )
        case 8:
            return UIColor(
                red: CGFloat((value >> 24) & 0xFF) / 255,
                green: CGFloat((value >> 16) & 0xFF) / 255,
                blue: CGFloat((value >> 8) & 0xFF) / 255,
                alpha: CGFloat(value & 0xFF) / 255
            )
        default:
            return nil
        }
    }

    private func loadTextureImage(named textureName: String) -> UIImage? {
        RemoteContentManager.cachedImage(named: textureName)
            ?? RemoteContentManager.cachedOrBundledImage(named: textureName)
    }

    @objc
    private func stepFrame(_ displayLink: CADisplayLink) {
        if lastUpdateTime == 0 {
            lastUpdateTime = displayLink.timestamp
            return
        }

        let deltaTime = Float(displayLink.timestamp - lastUpdateTime)
        lastUpdateTime = displayLink.timestamp

        updatePlayer(deltaTime: deltaTime)
        updateCamera(deltaTime: deltaTime)
    }

    private func updatePlayer(deltaTime: Float) {
        if let autoMoveTarget {
            movePlayerToward(autoMoveTarget, deltaTime: deltaTime)
            return
        }

        let input = joystickVector
        let magnitude = simd_length(input)

        if magnitude > 0.1 {
            playAnimation(named: "move")
        } else {
            stopPlayerAnimation()
        }

        guard magnitude > 0.08 else { return }

        let cameraRight = groundDirection(from: cameraNode.simdWorldRight)
        let cameraForward = groundDirection(from: cameraNode.simdWorldFront)

        let movementVector = (cameraRight * input.x) + (cameraForward * input.y)
        let movementDirection = simd_normalize(movementVector)

        let speed: Float = 50
        let distance = min(magnitude, 1) * speed * deltaTime

        // 🎯 TARGET POSITION
        var targetPosition =
            playerNode.simdPosition + movementDirection * distance
        targetPosition.y = getGroundTopY() + playerHeightOffset
        targetPosition = clampToGroundBounds(targetPosition)

        // 🔥 SMOOTH POSITION (Lerp)
        let positionSmooth: Float = 50  // vorher 10
        let t: Float = min(max(deltaTime * positionSmooth, 0), 1)

        playerNode.simdPosition =
            playerNode.simdPosition + (targetPosition - playerNode.simdPosition)
            * t

        // 🎯 TARGET ROTATION
        let targetAngle =
            atan2(movementDirection.x, movementDirection.z) - Float.pi / 2

        let currentAngle = playerNode.eulerAngles.y
        let rotationSpeed: Float = 8

        let newAngle =
            currentAngle + (targetAngle - currentAngle)
            * min(deltaTime * rotationSpeed, 1)

        playerNode.eulerAngles.y = newAngle
    }

    private func movePlayerToward(_ target: SIMD2<Float>, deltaTime: Float) {
        let targetPosition = simd_float3(
            target.x,
            getGroundTopY() + playerHeightOffset,
            target.y
        )
        let delta = targetPosition - playerNode.simdPosition
        let flatDelta = simd_float3(delta.x, 0, delta.z)
        let remainingDistance = simd_length(flatDelta)

        guard remainingDistance > 1.0 else {
            autoMoveTarget = nil
            stopPlayerAnimation()
            onAutoMoveFinished()
            return
        }

        playAnimation(named: "move")

        let movementDirection = flatDelta / remainingDistance
        let distance = min(remainingDistance, 42 * deltaTime)
        var nextPosition =
            playerNode.simdPosition + movementDirection * distance
        nextPosition.y = getGroundTopY() + playerHeightOffset
        playerNode.simdPosition = clampToGroundBounds(nextPosition)

        let targetAngle =
            atan2(movementDirection.x, movementDirection.z) - Float.pi / 2
        let currentAngle = playerNode.eulerAngles.y
        playerNode.eulerAngles.y =
            currentAngle + (targetAngle - currentAngle) * min(deltaTime * 8, 1)
    }

    private func groundDirection(from vector: simd_float3) -> simd_float3 {
        let flatVector = simd_float3(vector.x, 0, vector.z)
        let length = simd_length(flatVector)
        guard length > 0.001 else { return simd_float3(0, 0, -1) }
        return flatVector / length
    }

    private func loadAnimations() {
        animations.removeAll()

        playerVisualNode.enumerateChildNodes { node, _ in
            for key in node.animationKeys {
                if let animationPlayer = node.animationPlayer(forKey: key) {
                    let animation =
                        (animationPlayer.animation.copy() as? SCNAnimation)
                        ?? animationPlayer.animation
                    animation.repeatCount = .infinity
                    animation.blendInDuration = 0.2
                    animation.blendOutDuration = 0.2
                    animations.append(
                        PlayerAnimation(
                            node: node,
                            key: key,
                            animation: animation
                        )
                    )
                    node.removeAnimation(forKey: key)
                }
            }
        }
    }

    private var animations: [PlayerAnimation] = []

    private func clampToGroundBounds(_ position: simd_float3) -> simd_float3 {
        guard let ground = groundNode,
            let box = ground.geometry as? SCNBox
        else {
            return position
        }

        var pos = position
        let padding: Float = 2

        let limitX = Float(box.width) * 0.5 - padding
        let limitZ = Float(box.length) * 0.5 - padding

        pos.x = max(-limitX, min(limitX, pos.x))
        pos.z = max(-limitZ, min(limitZ, pos.z))

        return pos
    }

    private func updateCamera(deltaTime: Float) {
        let offset = SCNVector3(0, 30, 50)  // 🔥 Höhe + Abstand

        let targetPosition = SCNVector3(
            playerNode.position.x + offset.x,
            playerNode.position.y + offset.y,
            playerNode.position.z + offset.z
        )

        let strength = min(deltaTime * 3, 1)

        cameraNode.position = SCNVector3(
            cameraNode.position.x + (targetPosition.x - cameraNode.position.x)
                * strength,
            cameraNode.position.y + (targetPosition.y - cameraNode.position.y)
                * strength,
            cameraNode.position.z + (targetPosition.z - cameraNode.position.z)
                * strength
        )
        cameraNode.eulerAngles = SCNVector3(-atan2f(offset.y, offset.z), 0, 0)
    }
}

private enum TextureNames {
    static let ground = "bg_sar"
    static let skybox = "bg_sar"
}
