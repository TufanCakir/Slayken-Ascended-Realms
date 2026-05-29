//
//  BattleSceneView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SceneKit
import SwiftUI
import UIKit

private enum BattleSceneNodeCache {
    nonisolated(unsafe) static let modelCache = NSCache<NSString, SCNNode>()
}

struct BattleSceneView: UIViewRepresentable {
    @EnvironmentObject private var performanceMode: PerformanceModeManager

    let player: CharacterStats
    let enemies: [CharacterStats]
    let raidParticipants: [RaidParticipant]?
    let enemyHPs: [CGFloat]
    let selectedEnemyIndex: Int
    let playerAttackID: Int
    let allyAttackID: Int
    let allyAttackerParticipantID: String?
    let enemyAttackID: Int
    let attackingEnemyIndex: Int?
    let particleEffect: String?
    let particleTargetIndices: [Int]
    let comboStep: BattleComboStepDefinition?
    let particleEffects: [ParticleEffectDefinition]
    let groundTexture: String
    let skyboxTexture: String
    let battleSpeedMultiplier: Double
    let onSelectEnemy: (Int) -> Void

    func makeCoordinator() -> BattleSceneCoordinator {
        BattleSceneCoordinator(
            player: player,
            enemies: enemies,
            raidParticipants: raidParticipants,
            particleEffects: particleEffects,
            battleSpeedMultiplier: battleSpeedMultiplier,
            onSelectEnemy: onSelectEnemy
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
        context.coordinator.setupScene(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )
        context.coordinator.installTapGesture(on: view)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.preferredFramesPerSecond = performanceMode.sceneFramesPerSecond
        uiView.antialiasingMode =
            performanceMode.isReducedEffectsEnabled ? .none : .multisampling2X
        context.coordinator.updatePerformanceMode(
            reducedEffects: performanceMode.isReducedEffectsEnabled
        )
        context.coordinator.updateRaidParticipants(raidParticipants)
        context.coordinator.updateEnvironment(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )
        context.coordinator.updateBattleSpeedMultiplier(battleSpeedMultiplier)
        context.coordinator.updateEnemyHPs(enemyHPs)
        context.coordinator.updateSelectedEnemy(selectedEnemyIndex)
        context.coordinator.updateAttackTriggers(
            playerAttackID: playerAttackID,
            allyAttackID: allyAttackID,
            allyAttackerParticipantID: allyAttackerParticipantID,
            enemyAttackID: enemyAttackID,
            attackingEnemyIndex: attackingEnemyIndex,
            selectedEnemyIndex: selectedEnemyIndex,
            particleEffect: particleEffect,
            particleTargetIndices: particleTargetIndices,
            comboStep: comboStep
        )
    }
}

final class BattleSceneCoordinator {
    let scene = SCNScene()
    private let groundBaseDepth: CGFloat = 100
    private let groundThickness: CGFloat = 6

    private let playerStats: CharacterStats
    private let enemyStats: [CharacterStats]
    private var raidParticipants: [RaidParticipant]
    private let particleEffectDefinitions: [String: ParticleEffectDefinition]
    private let onSelectEnemy: (Int) -> Void
    private var battleSpeedMultiplier: Double

    private let cameraNode = SCNNode()
    private let playerRootNode = SCNNode()
    private var enemyRootNodes: [SCNNode] = []
    private var allyRootNodes: [SCNNode] = []
    private var fighterModelContainers: [String: SCNNode] = [:]
    private var fighterHomePositions: [String: SCNVector3] = [:]
    private var groundNode = SCNNode()
    private var enemyHPNodes: [SCNNode] = []
    private var enemySelectionNodes: [SCNNode] = []

    private var groundBox: SCNBox?
    private var groundMaterials: [SCNMaterial] = []
    private var defeatedFighterNames: Set<String> = []
    private var lastPlayerAttackID = 0
    private var lastAllyAttackID = 0
    private var lastEnemyAttackID = 0
    private var appliedGroundTexture = ""
    private var appliedSkyboxTexture = ""
    private var isReducedEffectsEnabled = false

    init(
        player: CharacterStats,
        enemies: [CharacterStats],
        raidParticipants: [RaidParticipant]?,
        particleEffects: [ParticleEffectDefinition],
        battleSpeedMultiplier: Double,
        onSelectEnemy: @escaping (Int) -> Void
    ) {
        self.playerStats = player
        self.enemyStats =
            enemies.isEmpty
            ? [
                CharacterStats(
                    name: "Enemy",
                    image: "",
                    model: "shela",
                    hp: 100,
                    attack: 10
                )
            ] : enemies
        self.raidParticipants = raidParticipants ?? []
        self.particleEffectDefinitions = Dictionary(
            uniqueKeysWithValues: particleEffects.map {
                ($0.id.lowercased(), $0)
            }
        )
        self.battleSpeedMultiplier = max(0.1, battleSpeedMultiplier)
        self.onSelectEnemy = onSelectEnemy
    }

    private var isRaidMode: Bool {
        !raidParticipants.isEmpty
    }

    func updatePerformanceMode(reducedEffects: Bool) {
        guard isReducedEffectsEnabled != reducedEffects else { return }
        isReducedEffectsEnabled = reducedEffects
        scene.rootNode.enumerateChildNodes { node, _ in
            guard let light = node.light, light.type == .directional else {
                return
            }
            light.castsShadow = !reducedEffects
            light.shadowSampleCount = reducedEffects ? 1 : 6
            light.shadowRadius = reducedEffects ? 1 : 3
        }
    }

    func updateRaidParticipants(_ participants: [RaidParticipant]?) {
        let updatedParticipants = participants ?? []
        guard
            participantSignature(for: updatedParticipants)
                != participantSignature(for: raidParticipants)
        else {
            return
        }

        raidParticipants = updatedParticipants
        guard !scene.rootNode.childNodes.isEmpty else { return }
        updateCameraForCurrentMode()
        rebuildRaidAllies()
        if isRaidMode {
            repositionRaidBossAndPlayer()
        }
    }

    func installTapGesture(on view: SCNView) {
        guard
            view.gestureRecognizers?.contains(where: { $0.name == "enemyTap" })
                != true
        else { return }
        let gesture = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap(_:))
        )
        gesture.name = "enemyTap"
        view.addGestureRecognizer(gesture)
    }

    func updateBattleSpeedMultiplier(_ multiplier: Double) {
        battleSpeedMultiplier = max(0.1, multiplier)
    }

    private func speedAdjustedDuration(_ duration: TimeInterval) -> TimeInterval
    {
        max(0.01, duration / battleSpeedMultiplier)
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view as? SCNView else { return }
        let location = gesture.location(in: view)
        for hit in view.hitTest(location, options: nil) {
            var node: SCNNode? = hit.node
            while let current = node {
                if let index = enemyRootNodes.firstIndex(of: current) {
                    onSelectEnemy(index)
                    return
                }
                node = current.parent
            }
        }
    }

    func updateEnemyHPs(_ values: [CGFloat]) {
        for index in enemyHPNodes.indices {
            let safe = max(
                0,
                min(1, values.indices.contains(index) ? values[index] : 0)
            )
            enemyHPNodes[index].scale.x = Float(safe)

            let enemyNode = enemyRootNodes[index]
            if safe <= 0.001 {
                playDeathAnimationIfNeeded(on: enemyNode)
            } else {
                resetDefeatedStateIfNeeded(on: enemyNode)
            }
        }
    }

    func updateSelectedEnemy(_ index: Int) {
        for nodeIndex in enemySelectionNodes.indices {
            enemySelectionNodes[nodeIndex].isHidden = nodeIndex != index
        }
    }

    func updateAttackTriggers(
        playerAttackID: Int,
        allyAttackID: Int,
        allyAttackerParticipantID: String?,
        enemyAttackID: Int,
        attackingEnemyIndex: Int?,
        selectedEnemyIndex: Int,
        particleEffect: String?,
        particleTargetIndices: [Int],
        comboStep: BattleComboStepDefinition?
    ) {
        if playerAttackID != lastPlayerAttackID {
            lastPlayerAttackID = playerAttackID
            if playerAttackID > 0,
                enemyRootNodes.indices.contains(selectedEnemyIndex),
                enemyRootNodes[selectedEnemyIndex].opacity > 0.05
            {
                playAttackAnimation(
                    attacker: playerRootNode,
                    defender: enemyRootNodes[selectedEnemyIndex],
                    animationSeed: playerAttackID,
                    particleEffect: particleEffect,
                    particleTargetIndices: particleTargetIndices,
                    comboStep: comboStep
                )
            }
        }

        if allyAttackID != lastAllyAttackID {
            lastAllyAttackID = allyAttackID
            if allyAttackID > 0,
                let allyAttackerParticipantID,
                let attacker = allyRootNode(for: allyAttackerParticipantID),
                let defender = enemyRootNodes.first,
                attacker.opacity > 0.05,
                defender.opacity > 0.05
            {
                playAttackAnimation(
                    attacker: attacker,
                    defender: defender,
                    animationSeed: allyAttackID,
                    particleEffect: nil,
                    particleTargetIndices: [],
                    comboStep: nil
                )
            }
        }

        if enemyAttackID != lastEnemyAttackID {
            lastEnemyAttackID = enemyAttackID
            if enemyAttackID > 0,
                let attackingEnemyIndex,
                enemyRootNodes.indices.contains(attackingEnemyIndex),
                enemyRootNodes[attackingEnemyIndex].opacity > 0.3
            {
                playAttackAnimation(
                    attacker: enemyRootNodes[attackingEnemyIndex],
                    defender: playerRootNode,
                    animationSeed: enemyAttackID,
                    particleEffect: nil,
                    particleTargetIndices: [],
                    comboStep: nil
                )
            }
        }
    }

    func setupScene(groundTexture: String, skyboxTexture: String) {
        guard scene.rootNode.childNodes.isEmpty else { return }

        scene.rootNode.addChildNode(makeCamera())
        scene.rootNode.addChildNode(makeLights())
        scene.rootNode.addChildNode(makeGround(textureName: groundTexture))

        let playerNode = makeFighterNode(
            for: playerStats,
            isEnemy: false,
            index: 0,
            total: 1
        )
        let enemyNodes = enemyStats.indices.map { index in
            makeFighterNode(
                for: enemyStats[index],
                isEnemy: true,
                index: index,
                total: enemyStats.count
            )
        }

        for enemyNode in enemyNodes {
            scene.rootNode.addChildNode(enemyNode)
        }
        scene.rootNode.addChildNode(playerNode)
        rebuildRaidAllies()

        updateEnvironment(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )
        updateEnemyHPs(Array(repeating: 1, count: enemyStats.count))
        updateSelectedEnemy(0)
    }

    func updateEnvironment(groundTexture: String, skyboxTexture: String) {
        if appliedGroundTexture != groundTexture {
            applyGroundTexture(named: groundTexture)
            appliedGroundTexture = groundTexture
        }

        if appliedSkyboxTexture != skyboxTexture {
            let skyboxImage = RemoteContentManager.cachedOrBundledImage(
                named: skyboxTexture
            )
            scene.background.contents = skyboxImage
            scene.lightingEnvironment.contents = skyboxImage
            appliedSkyboxTexture = skyboxTexture
        }
    }

    private func makeCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = isRaidMode ? 76 : 100

        cameraNode.camera = camera
        updateCameraForCurrentMode()

        return cameraNode
    }

    private func updateCameraForCurrentMode() {
        cameraNode.camera?.fieldOfView = isRaidMode ? 72 : 100

        if isRaidMode {
            cameraNode.position = SCNVector3(0, 12, 70)
            cameraNode.look(at: SCNVector3(0, 4, -4))
        } else {
            cameraNode.position = SCNVector3(0, 5, 20)
            cameraNode.look(at: SCNVector3(0, 0, 0))
        }
    }

    private func makeLights() -> SCNNode {
        let rig = SCNNode()

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 700
        ambient.color = UIColor(white: 0.85, alpha: 1)

        let ambientNode = SCNNode()
        ambientNode.light = ambient
        rig.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 1400
        directional.castsShadow = !isReducedEffectsEnabled
        directional.shadowMode = .modulated
        directional.shadowRadius = isReducedEffectsEnabled ? 1 : 3
        directional.shadowSampleCount = isReducedEffectsEnabled ? 1 : 6

        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-0.9, 0.5, 0.0)
        rig.addChildNode(directionalNode)

        return rig
    }

    private func makeGround(textureName: String) -> SCNNode {
        let box = SCNBox(
            width: groundBaseDepth,
            height: groundThickness,
            length: groundBaseDepth,
            chamferRadius: 1.2
        )
        box.widthSegmentCount = 12
        box.lengthSegmentCount = 11
        box.heightSegmentCount = 2
        box.materials = makeGroundMaterials(textureName: textureName)

        let node = SCNNode(geometry: box)
        node.position.y = -Float(groundThickness) * 1
        node.castsShadow = true

        groundBox = box
        groundNode = node

        return node
    }
    private func makeGroundMaterials(textureName: String) -> [SCNMaterial] {
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

        configureGroundMaterial(topMaterial, textureName: textureName)
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
        material.diffuse.contentsTransform = SCNMatrix4Identity

        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let aspectRatio = imageSize.width / imageSize.height
        if let box = groundBox {
            box.length = groundBaseDepth
            box.width = groundBaseDepth * aspectRatio
        }
    }

    private func getGroundTopY() -> Float {
        guard let ground = groundNode.geometry as? SCNBox else { return 0 }
        return groundNode.position.y + Float(ground.height) * 0.5
    }

    private func playAttackAnimation(
        attacker: SCNNode,
        defender: SCNNode,
        animationSeed: Int,
        particleEffect: String?,
        particleTargetIndices: [Int],
        comboStep: BattleComboStepDefinition?
    ) {
        attacker.removeAction(forKey: "attack")
        defender.removeAction(forKey: "hit")
        modelContainer(for: attacker)?.removeAction(forKey: "attackPose")
        modelContainer(for: defender)?.removeAction(forKey: "hitShake")
        resetCombatPosition(for: attacker)
        resetCombatPosition(for: defender)

        let start = attacker.position
        let defenderPosition = defender.position
        let direction = normalizedXZ(
            SCNVector3(
                defenderPosition.x - start.x,
                0,
                defenderPosition.z - start.z
            )
        )
        let distanceToEnemy = sqrt(
            pow(defenderPosition.x - start.x, 2)
                + pow(defenderPosition.z - start.z, 2)
        )

        let style = comboStep?.resolvedStyle ?? .dash
        let lungeDistance = lungeDistance(
            for: style,
            distanceToEnemy: distanceToEnemy
        )
        let windupDistance = windupDistance(for: style)

        let windupPosition = SCNVector3(
            start.x - direction.x * windupDistance,
            start.y,
            start.z - direction.z * windupDistance
        )
        let lungePosition = SCNVector3(
            start.x + direction.x * lungeDistance,
            start.y,
            start.z + direction.z * lungeDistance
        )

        let windup = SCNAction.move(
            to: windupPosition,
            duration: speedAdjustedDuration(windupDuration(for: style))
        )
        windup.timingMode = .easeOut

        let dash = SCNAction.move(
            to: lungePosition,
            duration: speedAdjustedDuration(dashDuration(for: style))
        )
        dash.timingMode = .easeInEaseOut

        let recover = SCNAction.move(
            to: start,
            duration: speedAdjustedDuration(recoverDuration(for: style))
        )
        recover.timingMode = .easeOut

        let anticipationDelay = SCNAction.wait(
            duration: speedAdjustedDuration(comboStep?.resolvedHoldDuration ?? 0.03)
        )
        let impact = SCNAction.run { [weak self, weak defender] _ in
            guard let self, let defender, let particleEffect else { return }
            if particleTargetIndices.isEmpty {
                self.spawnParticleEffect(
                    named: particleEffect,
                    at: defender.presentation.position
                )
                return
            }

            for index in particleTargetIndices
            where self.enemyRootNodes.indices.contains(index) {
                self.spawnParticleEffect(
                    named: particleEffect,
                    at: self.enemyRootNodes[index].presentation.position
                )
            }
        }

        let attackerPose = makeAttackPoseAction(
            seed: animationSeed,
            style: style
        )
        let impactShake = makeImpactShakeAction()
        let impactWait = speedAdjustedDuration(
            comboStep?.resolvedHitDelay ?? 0.22
        )

        modelContainer(for: attacker)?.runAction(
            SCNAction.sequence([
                SCNAction.wait(duration: max(0.02, impactWait * 0.45)),
                attackerPose,
            ]),
            forKey: "attackPose"
        )

        modelContainer(for: defender)?.runAction(
            SCNAction.sequence([
                SCNAction.wait(duration: impactWait),
                impactShake,
            ]),
            forKey: "hitShake"
        )

        attacker.runAction(
            SCNAction.sequence([
                windup,
                dash,
                impact,
                anticipationDelay,
                recover
            ]),
            forKey: "attack"
        )

        let hitDistance = max(0.25, distanceToEnemy * 0.05)
        let hitBack = SCNAction.move(
            by: SCNVector3(
                direction.x * hitDistance,
                0,
                direction.z * hitDistance
            ),
            duration: speedAdjustedDuration(0.07)
        )
        let returnBack = SCNAction.move(
            by: SCNVector3(
                -direction.x * hitDistance,
                0,
                -direction.z * hitDistance
            ),
            duration: speedAdjustedDuration(0.12)
        )

        defender.runAction(
            SCNAction.sequence([
                SCNAction.wait(duration: impactWait),
                hitBack,
                returnBack,
            ]),
            forKey: "hit"
        )
    }

    private func modelContainer(for root: SCNNode) -> SCNNode? {
        guard let name = root.name else { return nil }
        return fighterModelContainers[name]
    }

    private func resetCombatPosition(for root: SCNNode) {
        guard let name = root.name,
            let homePosition = fighterHomePositions[name]
        else {
            return
        }

        root.position = homePosition
    }

    private func allyRootNode(for participantID: String) -> SCNNode? {
        allyRootNodes.first { $0.name == "ally_\(participantID)" }
    }

    private func lungeDistance(
        for style: BattleComboStyle,
        distanceToEnemy: Float
    ) -> Float {
        switch style {
        case .dash:
            return max(1.2, distanceToEnemy * 0.45)
        case .slashRight, .slashLeft, .slashDown, .slashUp:
            return max(1.6, distanceToEnemy * 0.58)
        case .heavy:
            return max(1.4, distanceToEnemy * 0.52)
        case .finisher:
            return max(1.9, distanceToEnemy * 0.68)
        }
    }

    private func windupDistance(for style: BattleComboStyle) -> Float {
        switch style {
        case .dash:
            return 0.35
        case .slashRight, .slashDown, .slashUp:
            return 0.18
        case .slashLeft:
            return 0.18
        case .heavy:
            return 0.48
        case .finisher:
            return 0.62
        }
    }

    private func windupDuration(for style: BattleComboStyle) -> TimeInterval {
        switch style {
        case .dash:
            return 0.08
        case .slashRight, .slashLeft, .slashDown, .slashUp:
            return 0.05
        case .heavy:
            return 0.14
        case .finisher:
            return 0.18
        }
    }

    private func dashDuration(for style: BattleComboStyle) -> TimeInterval {
        switch style {
        case .dash:
            return 0.15
        case .slashRight, .slashLeft, .slashDown, .slashUp:
            return 0.11
        case .heavy:
            return 0.18
        case .finisher:
            return 0.22
        }
    }

    private func recoverDuration(for style: BattleComboStyle) -> TimeInterval {
        switch style {
        case .dash:
            return 0.28
        case .slashRight, .slashLeft, .slashDown, .slashUp:
            return 0.2
        case .heavy:
            return 0.24
        case .finisher:
            return 0.32
        }
    }

    private func makeAttackPoseAction(
        seed: Int,
        style: BattleComboStyle
    ) -> SCNAction {
        switch style {
        case .dash:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: -0.6,
                    y: 0,
                    z: 0,
                    duration: speedAdjustedDuration(0.15)
                ),
                SCNAction.rotateBy(
                    x: 0.6,
                    y: 0,
                    z: 0,
                    duration: speedAdjustedDuration(0.1)
                ),
            ])
        case .slashRight:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: 0,
                    y: 0.55,
                    z: -0.2,
                    duration: speedAdjustedDuration(0.08)
                ),
                SCNAction.rotateBy(
                    x: 0,
                    y: -0.55,
                    z: 0.2,
                    duration: speedAdjustedDuration(0.08)
                ),
            ])
        case .slashLeft:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: 0,
                    y: -0.55,
                    z: 0.2,
                    duration: speedAdjustedDuration(0.08)
                ),
                SCNAction.rotateBy(
                    x: 0,
                    y: 0.55,
                    z: -0.2,
                    duration: speedAdjustedDuration(0.08)
                ),
            ])
        case .slashDown:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: 0.65,
                    y: 0,
                    z: 0.22,
                    duration: speedAdjustedDuration(0.09)
                ),
                SCNAction.rotateBy(
                    x: -0.65,
                    y: 0,
                    z: -0.22,
                    duration: speedAdjustedDuration(0.09)
                ),
            ])
        case .slashUp:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: -0.65,
                    y: 0,
                    z: -0.22,
                    duration: speedAdjustedDuration(0.09)
                ),
                SCNAction.rotateBy(
                    x: 0.65,
                    y: 0,
                    z: 0.22,
                    duration: speedAdjustedDuration(0.09)
                ),
            ])
        case .heavy:
            return SCNAction.sequence([
                SCNAction.rotateBy(
                    x: -0.85,
                    y: 0,
                    z: 0,
                    duration: speedAdjustedDuration(0.15)
                ),
                SCNAction.rotateBy(
                    x: 0.85,
                    y: 0,
                    z: 0,
                    duration: speedAdjustedDuration(0.12)
                )
            ])
        case .finisher:
            return SCNAction.group([
                SCNAction.rotateBy(
                    x: 0,
                    y: .pi * 2,
                    z: 0,
                    duration: speedAdjustedDuration(0.36)
                ),
                SCNAction.sequence([
                    SCNAction.moveBy(
                        x: 0,
                        y: 1.5,
                        z: 0,
                        duration: speedAdjustedDuration(0.14)
                    ),
                    SCNAction.moveBy(
                        x: 0,
                        y: -1.5,
                        z: 0,
                        duration: speedAdjustedDuration(0.18)
                    )
                ])
            ])
        }
    }

    private func makeImpactShakeAction() -> SCNAction {
        SCNAction.sequence([
            SCNAction.moveBy(
                x: 0.2,
                y: 0,
                z: 0,
                duration: speedAdjustedDuration(0.05)
            ),
            SCNAction.moveBy(
                x: -0.4,
                y: 0,
                z: 0,
                duration: speedAdjustedDuration(0.05)
            ),
            SCNAction.moveBy(
                x: 0.2,
                y: 0,
                z: 0,
                duration: speedAdjustedDuration(0.05)
            ),
        ])
    }

    private func makeIdleBounceAction() -> SCNAction {
        SCNAction.repeatForever(
            SCNAction.sequence([
                SCNAction.moveBy(
                    x: 0,
                    y: 0.1,
                    z: 0,
                    duration: speedAdjustedDuration(0.8)
                ),
                SCNAction.moveBy(
                    x: 0,
                    y: -0.1,
                    z: 0,
                    duration: speedAdjustedDuration(0.8)
                ),
            ])
        )
    }

    private func playDeathAnimationIfNeeded(on root: SCNNode) {
        guard let name = root.name, !defeatedFighterNames.contains(name) else {
            return
        }

        defeatedFighterNames.insert(name)
        root.removeAction(forKey: "attack")
        root.removeAction(forKey: "hit")
        modelContainer(for: root)?.removeAction(forKey: "idle")
        modelContainer(for: root)?.removeAction(forKey: "attackPose")
        modelContainer(for: root)?.removeAction(forKey: "hitShake")

        root.runAction(
            SCNAction.sequence([
                SCNAction.rotateBy(
                    x: 0,
                    y: 0,
                    z: .pi / 2,
                    duration: speedAdjustedDuration(0.3)
                ),
                SCNAction.fadeOpacity(
                    to: 0,
                    duration: speedAdjustedDuration(0.4)
                ),
            ]),
            forKey: "death"
        )
    }

    private func resetDefeatedStateIfNeeded(on root: SCNNode) {
        guard let name = root.name, defeatedFighterNames.contains(name) else {
            return
        }

        defeatedFighterNames.remove(name)
        root.removeAction(forKey: "death")
        root.opacity = 1
        root.eulerAngles.z = 0
        modelContainer(for: root)?.opacity = 1
        modelContainer(for: root)?.position = SCNVector3(0, 0, 0)
        modelContainer(for: root)?.eulerAngles = SCNVector3(
            -Float.pi / 2,
            Float.pi / 2,
            0
        )
        modelContainer(for: root)?.runAction(
            makeIdleBounceAction(),
            forKey: "idle"
        )
    }

    private func spawnParticleEffect(
        named effect: String,
        at position: SCNVector3
    ) {
        guard !isReducedEffectsEnabled else { return }

        let definition = particleDefinition(for: effect)
        let node = SCNNode()
        node.position = SCNVector3(
            position.x,
            position.y + Float(definition.resolvedYOffset),
            position.z
        )
        node.addChildNode(makeEffectCoreNode(for: definition, effect: effect))
        for particles in makeParticleSystems(for: definition, effect: effect) {
            node.addParticleSystem(particles)
        }
        scene.rootNode.addChildNode(node)
        node.runAction(
            SCNAction.sequence([
                SCNAction.wait(
                    duration: speedAdjustedDuration(
                        definition.resolvedCleanupDelay
                    )
                ),
                SCNAction.removeFromParentNode(),
            ])
        )
    }

    private func makeParticleSystems(
        for definition: ParticleEffectDefinition,
        effect: String
    ) -> [SCNParticleSystem] {
        switch effect.lowercased() {
        case "fire":
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .glow),
                    birthRateMultiplier: 1.0,
                    sizeMultiplier: 1.2,
                    velocityMultiplier: 1.0,
                    spreadingAngle: 88,
                    acceleration: SCNVector3(0, 2.8, 0)
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .ember),
                    birthRateMultiplier: 0.55,
                    sizeMultiplier: 0.55,
                    velocityMultiplier: 1.35,
                    spreadingAngle: 46,
                    acceleration: SCNVector3(0, 4.2, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .smoke),
                    birthRateMultiplier: 0.18,
                    sizeMultiplier: 1.8,
                    velocityMultiplier: 0.55
                ),
            ]
        case "ice", "crystal":
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .shard),
                    birthRateMultiplier: 0.85,
                    sizeMultiplier: 0.7,
                    velocityMultiplier: 1.25,
                    spreadingAngle: 58,
                    acceleration: SCNVector3(0, -1.2, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.22,
                    sizeMultiplier: 1.45,
                    velocityMultiplier: 0.48
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .mist),
                    birthRateMultiplier: 0.34,
                    sizeMultiplier: 1.3,
                    velocityMultiplier: 0.42,
                    spreadingAngle: 120,
                    acceleration: SCNVector3(0, 0.8, 0)
                ),
            ]
        case "void":
            return [
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.28,
                    sizeMultiplier: 1.85,
                    velocityMultiplier: 0.35
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .glow),
                    birthRateMultiplier: 0.9,
                    sizeMultiplier: 1.0,
                    velocityMultiplier: 0.9,
                    spreadingAngle: 140,
                    acceleration: SCNVector3(0, 0.5, 0)
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .spark),
                    birthRateMultiplier: 0.45,
                    sizeMultiplier: 0.38,
                    velocityMultiplier: 1.6,
                    spreadingAngle: 38,
                    acceleration: SCNVector3(0, 1.5, 0)
                ),
            ]
        case "light":
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .flare),
                    birthRateMultiplier: 0.72,
                    sizeMultiplier: 1.1,
                    velocityMultiplier: 0.75,
                    spreadingAngle: 62,
                    acceleration: SCNVector3(0, 1.2, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.16,
                    sizeMultiplier: 1.7,
                    velocityMultiplier: 0.32
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .spark),
                    birthRateMultiplier: 0.38,
                    sizeMultiplier: 0.28,
                    velocityMultiplier: 1.3,
                    spreadingAngle: 44,
                    acceleration: SCNVector3(0, 2.0, 0)
                ),
            ]
        case "storm":
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .bolt),
                    birthRateMultiplier: 0.78,
                    sizeMultiplier: 0.7,
                    velocityMultiplier: 1.7,
                    spreadingAngle: 24,
                    acceleration: SCNVector3(0, 0.4, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.20,
                    sizeMultiplier: 1.35,
                    velocityMultiplier: 0.62
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .spark),
                    birthRateMultiplier: 0.52,
                    sizeMultiplier: 0.25,
                    velocityMultiplier: 1.9,
                    spreadingAngle: 32,
                    acceleration: SCNVector3(0, 1.0, 0)
                ),
            ]
        case "ash":
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .smoke),
                    birthRateMultiplier: 0.42,
                    sizeMultiplier: 1.55,
                    velocityMultiplier: 0.5,
                    spreadingAngle: 128,
                    acceleration: SCNVector3(0, 0.45, 0)
                ),
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .ember),
                    birthRateMultiplier: 0.28,
                    sizeMultiplier: 0.45,
                    velocityMultiplier: 1.25,
                    spreadingAngle: 54,
                    acceleration: SCNVector3(0, 1.8, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.12,
                    sizeMultiplier: 1.8,
                    velocityMultiplier: 0.28
                ),
            ]
        default:
            return [
                makeBurstParticles(
                    definition: definition,
                    image: particleSprite(style: .glow),
                    birthRateMultiplier: 0.9,
                    sizeMultiplier: 1.0,
                    velocityMultiplier: 1.0,
                    spreadingAngle: definition.resolvedSpreadingAngle,
                    acceleration: SCNVector3(0, 1.2, 0)
                ),
                makeRingParticles(
                    definition: definition,
                    image: particleSprite(style: .ring),
                    birthRateMultiplier: 0.14,
                    sizeMultiplier: 1.3,
                    velocityMultiplier: 0.42
                ),
            ]
        }
    }

    private func makeBurstParticles(
        definition: ParticleEffectDefinition,
        image: UIImage,
        birthRateMultiplier: Double,
        sizeMultiplier: Double,
        velocityMultiplier: Double,
        spreadingAngle: Double,
        acceleration: SCNVector3
    ) -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.loops = false
        particles.birthRate = definition.resolvedBirthRate * birthRateMultiplier
        particles.emissionDuration = speedAdjustedDuration(
            definition.resolvedEmissionDuration
        )
        particles.particleLifeSpan = speedAdjustedDuration(
            definition.resolvedLifeSpan
        )
        particles.particleLifeSpanVariation =
            speedAdjustedDuration(definition.resolvedLifeSpanVariation)
        particles.particleSize = definition.resolvedSize * sizeMultiplier
        particles.particleSizeVariation = definition.resolvedSizeVariation
        particles.particleVelocity =
            definition.resolvedVelocity * velocityMultiplier
        particles.particleVelocityVariation =
            definition.resolvedVelocityVariation * velocityMultiplier
        particles.spreadingAngle = spreadingAngle
        particles.blendMode = .additive
        particles.birthLocation = .surface
        particles.emitterShape = SCNSphere(radius: 0.22)
        particles.particleImage = image
        particles.isLightingEnabled = true
        particles.stretchFactor = 0.18
        particles.dampingFactor = 0.12
        particles.acceleration = acceleration
        particles.particleColor = UIColor(
            red: definition.red,
            green: definition.green,
            blue: definition.blue,
            alpha: definition.resolvedAlpha
        )
        return particles
    }

    private func makeRingParticles(
        definition: ParticleEffectDefinition,
        image: UIImage,
        birthRateMultiplier: Double,
        sizeMultiplier: Double,
        velocityMultiplier: Double
    ) -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.loops = false
        particles.birthRate = definition.resolvedBirthRate * birthRateMultiplier
        particles.emissionDuration = max(
            0.05,
            speedAdjustedDuration(definition.resolvedEmissionDuration * 0.75)
        )
        particles.particleLifeSpan = speedAdjustedDuration(
            definition.resolvedLifeSpan * 1.15
        )
        particles.particleLifeSpanVariation =
            speedAdjustedDuration(definition.resolvedLifeSpanVariation * 0.5)
        particles.particleSize = definition.resolvedSize * sizeMultiplier
        particles.particleSizeVariation = definition.resolvedSizeVariation * 0.3
        particles.particleVelocity =
            definition.resolvedVelocity * velocityMultiplier
        particles.particleVelocityVariation =
            definition.resolvedVelocityVariation * 0.35
        particles.spreadingAngle = 10
        particles.blendMode = .additive
        particles.birthLocation = .surface
        particles.emitterShape = SCNTorus(ringRadius: 0.28, pipeRadius: 0.04)
        particles.particleImage = image
        particles.isLightingEnabled = true
        particles.acceleration = SCNVector3(0, 0.15, 0)
        particles.particleColor = UIColor(
            red: definition.red,
            green: definition.green,
            blue: definition.blue,
            alpha: definition.resolvedAlpha * 0.9
        )
        return particles
    }

    private func makeEffectCoreNode(
        for definition: ParticleEffectDefinition,
        effect: String
    ) -> SCNNode {
        let sphere = SCNSphere(
            radius: effect.lowercased() == "void" ? 0.42 : 0.28
        )
        sphere.segmentCount = 24

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(
            red: definition.red,
            green: definition.green,
            blue: definition.blue,
            alpha: min(1.0, definition.resolvedAlpha * 0.55)
        )
        material.emission.contents = UIColor(
            red: definition.red,
            green: definition.green,
            blue: definition.blue,
            alpha: 1.0
        )
        material.blendMode = .add
        material.lightingModel = .constant
        material.isDoubleSided = true
        sphere.firstMaterial = material

        let node = SCNNode(geometry: sphere)
        node.opacity = 0.0
        node.scale = SCNVector3(0.2, 0.2, 0.2)
        node.runAction(
            SCNAction.sequence([
                SCNAction.group([
                    SCNAction.fadeOpacity(
                        to: 0.95,
                        duration: speedAdjustedDuration(0.05)
                    ),
                    SCNAction.scale(
                        to: 1.0,
                        duration: speedAdjustedDuration(0.10)
                    ),
                ]),
                SCNAction.group([
                    SCNAction.fadeOut(duration: speedAdjustedDuration(0.20)),
                    SCNAction.scale(
                        to: effect.lowercased() == "storm" ? 1.35 : 1.55,
                        duration: speedAdjustedDuration(0.20)
                    ),
                ]),
                SCNAction.removeFromParentNode(),
            ])
        )
        return node
    }

    private enum ParticleSpriteStyle {
        case glow
        case ember
        case shard
        case ring
        case smoke
        case mist
        case flare
        case spark
        case bolt
    }

    private func particleSprite(style: ParticleSpriteStyle) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 96, height: 96)
        )
        return renderer.image { context in
            let cg = context.cgContext
            cg.setAllowsAntialiasing(true)

            switch style {
            case .glow, .flare, .mist:
                let colors =
                    [
                        UIColor.white
                            .withAlphaComponent(style == .flare ? 1.0 : 0.9)
                            .cgColor,
                        UIColor.white
                            .withAlphaComponent(style == .mist ? 0.12 : 0.0)
                            .cgColor,
                    ] as CFArray
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors,
                    locations: [0.0, 1.0]
                )
                cg.drawRadialGradient(
                    gradient!,
                    startCenter: CGPoint(x: 48, y: 48),
                    startRadius: 2,
                    endCenter: CGPoint(x: 48, y: 48),
                    endRadius: style == .flare ? 44 : 38,
                    options: .drawsAfterEndLocation
                )
            case .ember, .spark:
                cg.setFillColor(UIColor.white.cgColor)
                cg.fillEllipse(in: CGRect(x: 34, y: 34, width: 28, height: 28))
            case .shard:
                cg.setFillColor(UIColor.white.cgColor)
                cg.move(to: CGPoint(x: 48, y: 10))
                cg.addLine(to: CGPoint(x: 68, y: 48))
                cg.addLine(to: CGPoint(x: 48, y: 86))
                cg.addLine(to: CGPoint(x: 28, y: 48))
                cg.closePath()
                cg.fillPath()
            case .ring:
                cg.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
                cg.setLineWidth(8)
                cg.strokeEllipse(
                    in: CGRect(x: 18, y: 18, width: 60, height: 60)
                )
            case .smoke:
                cg.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
                cg.fillEllipse(in: CGRect(x: 18, y: 22, width: 34, height: 34))
                cg.fillEllipse(in: CGRect(x: 40, y: 18, width: 30, height: 30))
                cg.fillEllipse(in: CGRect(x: 34, y: 40, width: 32, height: 32))
            case .bolt:
                cg.setFillColor(UIColor.white.cgColor)
                cg.move(to: CGPoint(x: 44, y: 8))
                cg.addLine(to: CGPoint(x: 62, y: 38))
                cg.addLine(to: CGPoint(x: 50, y: 38))
                cg.addLine(to: CGPoint(x: 62, y: 88))
                cg.addLine(to: CGPoint(x: 34, y: 52))
                cg.addLine(to: CGPoint(x: 46, y: 52))
                cg.closePath()
                cg.fillPath()
            }
        }
    }

    private func particleDefinition(for effect: String)
        -> ParticleEffectDefinition
    {
        particleEffectDefinitions[effect.lowercased()]
            ?? particleEffectDefinitions["neutral"]
            ?? ParticleEffectDefinition(
                id: "neutral",
                name: "Neutral Spark",
                red: 0.92,
                green: 0.96,
                blue: 1.0,
                alpha: 1,
                birthRate: nil,
                emissionDuration: nil,
                lifeSpan: nil,
                lifeSpanVariation: nil,
                size: nil,
                sizeVariation: nil,
                velocity: nil,
                velocityVariation: nil,
                spreadingAngle: nil,
                yOffset: nil,
                cleanupDelay: nil
            )
    }

    private func normalizedXZ(_ vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.z * vector.z)
        guard length > 0.001 else {
            return SCNVector3(0, 0, -1)
        }

        return SCNVector3(vector.x / length, 0, vector.z / length)
    }

    private func makeFighterNode(
        for stats: CharacterStats,
        isEnemy: Bool,
        index: Int,
        total: Int
    )
        -> SCNNode
    {
        let root = isEnemy ? SCNNode() : playerRootNode
        root.childNodes.forEach { $0.removeFromParentNode() }
        root.name = isEnemy ? "enemy_\(index)" : "player"

        let modelContainer = SCNNode()
        let modelNode = loadModel(
            named: stats.battleModel ?? stats.model,
            stats: stats
        )
        modelContainer.addChildNode(modelNode)
        root.addChildNode(modelContainer)
        fighterModelContainers[root.name ?? ""] = modelContainer

        let bounds = modelNode.boundingBox

        let centerX = (bounds.min.x + bounds.max.x) * 0.5
        let centerZ = (bounds.min.z + bounds.max.z) * 0.5

        modelNode.pivot = SCNMatrix4MakeTranslation(
            centerX,
            bounds.min.y,
            centerZ
        )

        let height = max(bounds.max.y - bounds.min.y, 0.01)
        let scale: Float = 4.0 / height
        modelContainer.scale = SCNVector3(scale, scale, scale)

        modelContainer.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi / 2, 0)
        if !isEnemy {
            addSkinSceneEffects(
                for: stats,
                to: modelContainer,
                bounds: bounds
            )
        }
        modelContainer.runAction(makeIdleBounceAction(), forKey: "idle")

        let groundY = getGroundTopY()

        let yOffset: Float = 3
        let xOffset: Float = 2
        let zOffset: Float = 10

        if isEnemy {
            if isRaidMode {
                root.position = SCNVector3(0, groundY + yOffset, -2.8)
            } else {
                let spacing: Float = 8
                let centerOffset = (Float(total - 1) * spacing) * 0.5
                root.position = SCNVector3(
                    -xOffset + Float(index) * spacing - centerOffset,
                    groundY + yOffset,
                    -zOffset
                )
            }
            if let name = root.name {
                fighterHomePositions[name] = root.position
            }
            root.eulerAngles.y = Float.pi
            addEnemyHUD(to: root, index: index)
            enemyRootNodes.append(root)
        } else {
            if isRaidMode {
                let slots = visibleRaidParticipants
                let localSlot = max(
                    0,
                    slots.firstIndex(where: \.isLocalPlayer) ?? 0
                )
                root.position = raidParticipantPosition(
                    slot: localSlot,
                    totalSlots: max(slots.count, 1),
                    groundY: groundY + yOffset
                )
            } else {
                root.position = SCNVector3(xOffset, groundY + yOffset, zOffset)
            }
            if let name = root.name {
                fighterHomePositions[name] = root.position
            }
            root.eulerAngles.y = 0
        }

        return root
    }

    private var visibleRaidParticipants: [RaidParticipant] {
        raidParticipants.filter {
            $0.connectionState == .inRaid || $0.connectionState == .connected
        }
    }

    private func rebuildRaidAllies() {
        allyRootNodes.forEach { node in
            fighterModelContainers[node.name ?? ""] = nil
            node.removeFromParentNode()
        }
        allyRootNodes.removeAll()

        guard isRaidMode else { return }

        let participants = visibleRaidParticipants
        let allyParticipants = participants.filter { !$0.isLocalPlayer }
        let groundY = getGroundTopY() + 3

        for participant in allyParticipants {
            let slot =
                participants.firstIndex(where: { $0.id == participant.id }) ?? 0
            let node = makeRaidAllyNode(
                participant: participant,
                slot: slot,
                totalSlots: max(participants.count, 1),
                groundY: groundY
            )
            allyRootNodes.append(node)
            scene.rootNode.addChildNode(node)
        }
    }

    private func repositionRaidBossAndPlayer() {
        let groundY = getGroundTopY() + 3
        if let bossNode = enemyRootNodes.first {
            bossNode.position = SCNVector3(0, groundY, -2.8)
            if let name = bossNode.name {
                fighterHomePositions[name] = bossNode.position
            }
        }

        let participants = visibleRaidParticipants
        let localSlot = participants.firstIndex(where: \.isLocalPlayer) ?? 0
        playerRootNode.position = raidParticipantPosition(
            slot: localSlot,
            totalSlots: max(participants.count, 1),
            groundY: groundY
        )
        if let name = playerRootNode.name {
            fighterHomePositions[name] = playerRootNode.position
        }
    }

    private func raidParticipantPosition(
        slot: Int,
        totalSlots: Int,
        groundY: Float
    ) -> SCNVector3 {

        let safeTotalSlots = max(totalSlots, 1)

        let startAngle = Double.pi * 0.0
        let endAngle = Double.pi * 1.0

        let progress =
            safeTotalSlots == 1
            ? 0.5
            : Double(slot) / Double(safeTotalSlots - 1)

        let angle = startAngle + (endAngle - startAngle) * progress

        let radius: Float = 10.0
        let centerZ: Float = 30

        // NEU
        let centerX: Float = 3.0

        return SCNVector3(
            centerX + Float(cos(angle)) * radius,
            groundY,
            centerZ + Float(sin(angle)) * radius
        )
    }

    private func makeRaidAllyNode(
        participant: RaidParticipant,
        slot: Int,
        totalSlots: Int,
        groundY: Float
    ) -> SCNNode {
        let root = SCNNode()
        root.name = "ally_\(participant.id)"

        let modelContainer = SCNNode()
        let allyModelName = participant.characterModel ?? playerStats.model
        let allyTextureName =
            participant.characterTexture ?? playerStats.texture
        let modelNode = loadModel(
            named: allyModelName,
            stats: CharacterStats(
                name: participant.displayName,
                image: "",
                model: allyModelName,
                texture: allyTextureName,
                hp: CGFloat(participant.maxHP),
                attack: 1
            )
        )
        modelContainer.addChildNode(modelNode)
        root.addChildNode(modelContainer)
        fighterModelContainers[root.name ?? ""] = modelContainer

        let bounds = modelNode.boundingBox
        let centerX = (bounds.min.x + bounds.max.x) * 0.5
        let centerZ = (bounds.min.z + bounds.max.z) * 0.5
        modelNode.pivot = SCNMatrix4MakeTranslation(
            centerX,
            bounds.min.y,
            centerZ
        )

        let height = max(bounds.max.y - bounds.min.y, 0.01)
        let scale: Float = 3.7 / height
        modelContainer.scale = SCNVector3(scale, scale, scale)
        modelContainer.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi / 2, 0)
        modelContainer.opacity = participant.currentHP > 0 ? 0.86 : 0.25
        modelContainer.runAction(makeIdleBounceAction(), forKey: "idle")

        root.position = raidParticipantPosition(
            slot: slot,
            totalSlots: totalSlots,
            groundY: groundY
        )
        if let name = root.name {
            fighterHomePositions[name] = root.position
        }
        root.eulerAngles.y = 0
        addRaidAllyMarker(to: root, participant: participant)

        return root
    }

    private func addRaidAllyMarker(
        to root: SCNNode,
        participant: RaidParticipant
    ) {
        let ring = SCNNode(
            geometry: SCNTorus(ringRadius: 1.0, pipeRadius: 0.04)
        )
        ring.geometry?.firstMaterial?.diffuse.contents = raidRoleColor(
            for: participant
        )
        ring.eulerAngles.x = Float.pi / 2
        ring.position = SCNVector3(0, 0.02, 0)
        root.addChildNode(ring)
    }

    private func raidRoleColor(for participant: RaidParticipant) -> UIColor {
        switch participant.role {
        case .tank:
            return .systemBlue
        case .healer:
            return .systemGreen
        case .damageDealer:
            return .systemRed
        case .supporter:
            return .systemCyan
        case nil:
            return participant.isBot ? .systemTeal : .white
        }
    }

    private func participantSignature(for participants: [RaidParticipant])
        -> String
    {
        participants.map { participant in
            "\(participant.id)-\(participant.currentHP)-\(participant.connectionState.rawValue)"
        }
        .joined(separator: "|")
    }

    private func addEnemyHUD(to root: SCNNode, index: Int) {
        let hpBackground = SCNNode(geometry: SCNPlane(width: 1.6, height: 0.12))
        hpBackground.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            .withAlphaComponent(0.72)
        hpBackground.position = SCNVector3(0, 4.7, 0)
        hpBackground.constraints = [SCNBillboardConstraint()]
        root.addChildNode(hpBackground)

        let hpFill = SCNNode(geometry: SCNPlane(width: 1.52, height: 0.08))
        hpFill.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
        hpFill.position = SCNVector3(-0.76, 4.71, 0.01)
        hpFill.pivot = SCNMatrix4MakeTranslation(-0.76, 0, 0)
        hpFill.constraints = [SCNBillboardConstraint()]
        root.addChildNode(hpFill)
        enemyHPNodes.append(hpFill)

        let selection = SCNNode(
            geometry: SCNTorus(ringRadius: 1.05, pipeRadius: 0.035)
        )
        selection.geometry?.firstMaterial?.diffuse.contents =
            UIColor.systemYellow
        selection.eulerAngles.x = Float.pi / 2
        selection.position = SCNVector3(0, 0.00, 0)
        selection.isHidden = index != 0
        root.addChildNode(selection)
        enemySelectionNodes.append(selection)
    }

    private func loadModel(named modelName: String, stats: CharacterStats)
        -> SCNNode
    {
        let cacheKey = skinCacheKey(modelName: modelName, stats: stats)
        if let cachedNode = BattleSceneNodeCache.modelCache.object(
            forKey: cacheKey
        ) {
            return cachedNode.clone()
        }

        let container = SCNNode()

        if let scene = loadModelScene(named: modelName) {
            for child in scene.rootNode.childNodes {
                container.addChildNode(child.clone())
            }
            removeModelAnimations(from: container)
            applyCharacterMaterial(stats, to: container)
        }

        BattleSceneNodeCache.modelCache.setObject(container, forKey: cacheKey)
        return container.clone()
    }

    private func skinCacheKey(modelName: String, stats: CharacterStats)
        -> NSString
    {
        [
            modelName,
            stats.texture ?? "-",
            stats.materialColor ?? "-",
            stats.emissionColor ?? "-",
            String(stats.emissionIntensity ?? -1),
            String(stats.roughness ?? -1),
            String(stats.metalness ?? -1),
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

    private func removeModelAnimations(from rootNode: SCNNode) {
        rootNode.removeAllAnimations()
        rootNode.enumerateChildNodes { node, _ in
            for key in node.animationKeys {
                node.removeAnimation(forKey: key)
            }
            node.removeAllAnimations()
        }
    }

    private func applyCharacterMaterial(
        _ stats: CharacterStats,
        to rootNode: SCNNode
    ) {
        let image =
            stats.texture.flatMap { textureName in
                textureName.isEmpty ? nil : loadTextureImage(named: textureName)
            }
        let materialColor = color(from: stats.materialColor)
        let emissionColor = color(from: stats.emissionColor)
        guard
            image != nil || materialColor != nil || emissionColor != nil
                || stats.roughness != nil || stats.metalness != nil
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
                if let emissionIntensity = stats.emissionIntensity {
                    material.emission.intensity = CGFloat(emissionIntensity)
                }
                material.roughness.contents = stats.roughness ?? 0.85
                material.metalness.contents = stats.metalness ?? 0.0
                material.isDoubleSided = true
            }

            copiedGeometry.materials = copiedMaterials
            node.geometry = copiedGeometry
        }
    }

    private func addSkinSceneEffects(
        for stats: CharacterStats,
        to rootNode: SCNNode,
        bounds: (min: SCNVector3, max: SCNVector3)
    ) {
        guard !isReducedEffectsEnabled else { return }

        let width = max(bounds.max.x - bounds.min.x, 0.1)
        let depth = max(bounds.max.z - bounds.min.z, 0.1)
        let height = max(bounds.max.y - bounds.min.y, 0.1)
        let radius =
            CGFloat(max(width, depth)) * CGFloat(stats.auraRadius ?? 0.62)

        if let auraColor = color(from: stats.auraColor) {
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
                CGFloat(stats.auraIntensity ?? 1.0)
            aura.position = SCNVector3(0, bounds.min.y + 0.08, 0)
            aura.eulerAngles.x = Float.pi / 2
            aura.opacity = 0.72
            rootNode.addChildNode(aura)
        }

        if let shadowColor = color(from: stats.shadowColor) {
            let shadow = SCNNode(
                geometry: SCNCylinder(
                    radius: radius * 0.95,
                    height: 0.012
                )
            )
            shadow.geometry?.firstMaterial?.diffuse.contents =
                shadowColor.withAlphaComponent(CGFloat(stats.shadowOpacity ?? 0.32))
            shadow.geometry?.firstMaterial?.isDoubleSided = true
            shadow.position = SCNVector3(0, bounds.min.y + 0.02, 0)
            rootNode.addChildNode(shadow)
        }

        if stats.particleEffect != nil {
            let particleSystem = SCNParticleSystem()
            particleSystem.birthRate = 70
            particleSystem.particleLifeSpan = 0.9
            particleSystem.particleLifeSpanVariation = 0.3
            particleSystem.particleSize = 0.08
            particleSystem.particleSizeVariation = 0.04
            particleSystem.spreadingAngle = 140
            particleSystem.emitterShape = SCNSphere(radius: radius * 0.65)
            particleSystem.particleColor =
                color(from: stats.auraColor)
                ?? color(from: stats.emissionColor)
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
}
