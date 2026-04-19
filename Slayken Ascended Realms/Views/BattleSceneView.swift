//
//  BattleSceneView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 12.04.26.
//

import SceneKit
import SwiftUI
import UIKit

struct BattleSceneView: UIViewRepresentable {
    let player: CharacterStats
    let enemy: CharacterStats
    let enemyHP: CGFloat
    let playerAttackID: Int
    let enemyAttackID: Int
    let particleEffect: String?
    let groundTexture: String
    let skyboxTexture: String

    func makeCoordinator() -> BattleSceneCoordinator {
        BattleSceneCoordinator(player: player, enemy: enemy)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = context.coordinator.scene
        view.backgroundColor = .black
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.isPlaying = true
        view.preferredFramesPerSecond = 60

        context.coordinator.setupScene(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateEnvironment(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )
        context.coordinator.updateEnemyHP(enemyHP)
        context.coordinator.updateAttackTriggers(
            playerAttackID: playerAttackID,
            enemyAttackID: enemyAttackID,
            particleEffect: particleEffect
        )
    }
}

final class BattleSceneCoordinator {
    let scene = SCNScene()
    private let groundBaseDepth: CGFloat = 100
    private let groundThickness: CGFloat = 6

    private let playerStats: CharacterStats
    private let enemyStats: CharacterStats

    private let cameraNode = SCNNode()
    private let playerRootNode = SCNNode()
    private let enemyRootNode = SCNNode()
    private var groundNode = SCNNode()
    private var enemyHPNode: SCNNode?

    private var groundBox: SCNBox?
    private var groundMaterials: [SCNMaterial] = []
    private var lastPlayerAttackID = 0
    private var lastEnemyAttackID = 0

    init(player: CharacterStats, enemy: CharacterStats) {
        self.playerStats = player
        self.enemyStats = enemy
    }

    func updateEnemyHP(_ value: CGFloat) {
        let safe = max(0, min(1, value))
        enemyHPNode?.scale.x = Float(safe)
    }

    func updateAttackTriggers(
        playerAttackID: Int,
        enemyAttackID: Int,
        particleEffect: String?
    ) {
        if playerAttackID != lastPlayerAttackID {
            lastPlayerAttackID = playerAttackID
            if playerAttackID > 0 {
                playAttackAnimation(
                    attacker: playerRootNode,
                    defender: enemyRootNode,
                    particleEffect: particleEffect
                )
            }
        }

        if enemyAttackID != lastEnemyAttackID {
            lastEnemyAttackID = enemyAttackID
            if enemyAttackID > 0 {
                playAttackAnimation(
                    attacker: enemyRootNode,
                    defender: playerRootNode,
                    particleEffect: nil
                )
            }
        }
    }

    func setupScene(groundTexture: String, skyboxTexture: String) {
        guard scene.rootNode.childNodes.isEmpty else { return }

        scene.rootNode.addChildNode(makeCamera())
        scene.rootNode.addChildNode(makeLights())
        scene.rootNode.addChildNode(makeGround(textureName: groundTexture))

        let enemyNode = makeFighterNode(for: enemyStats, isEnemy: true)
        let playerNode = makeFighterNode(for: playerStats, isEnemy: false)

        scene.rootNode.addChildNode(enemyNode)
        scene.rootNode.addChildNode(playerNode)

        updateEnvironment(
            groundTexture: groundTexture,
            skyboxTexture: skyboxTexture
        )
        updateEnemyHP(1)
    }

    func updateEnvironment(groundTexture: String, skyboxTexture: String) {
        applyGroundTexture(named: groundTexture)
        scene.background.contents = UIImage(named: skyboxTexture)
        scene.lightingEnvironment.contents = UIImage(named: skyboxTexture)
    }

    private func makeCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 100

        cameraNode.camera = camera

        // 🔥 SIDE VIEW (leicht schräg von rechts)
        cameraNode.position = SCNVector3(0, 5, 20)
        cameraNode.look(at: SCNVector3(0, 0, 0))

        return cameraNode
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
        directional.castsShadow = true
        directional.shadowMode = .deferred
        directional.shadowSampleCount = 16

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
        guard let image = UIImage(named: textureName) else {
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
        particleEffect: String?
    ) {
        attacker.removeAction(forKey: "attack")
        defender.removeAction(forKey: "hit")

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

        let lungeDistance = max(1.2, distanceToEnemy * 0.45)
        let windupDistance: Float = 0.35

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

        let windup = SCNAction.move(to: windupPosition, duration: 0.08)
        windup.timingMode = .easeOut

        let lunge = SCNAction.group([
            SCNAction.move(to: lungePosition, duration: 0.12),
            SCNAction.rotateBy(x: -0.18, y: 0, z: 0, duration: 0.12),
        ])
        lunge.timingMode = .easeIn

        let recover = SCNAction.group([
            SCNAction.move(to: start, duration: 0.18),
            SCNAction.rotateBy(x: 0.18, y: 0, z: 0, duration: 0.18),
        ])
        recover.timingMode = .easeOut

        let impact = SCNAction.run { [weak self, weak defender] _ in
            guard let self, let defender, let particleEffect else { return }
            self.spawnParticleEffect(
                named: particleEffect,
                at: defender.presentation.position
            )
        }

        attacker.runAction(
            SCNAction.sequence([
                windup, lunge, impact, SCNAction.wait(duration: 0.04), recover,
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
            duration: 0.07
        )
        let returnBack = SCNAction.move(
            by: SCNVector3(
                -direction.x * hitDistance,
                0,
                -direction.z * hitDistance
            ),
            duration: 0.12
        )

        defender.runAction(
            SCNAction.sequence([
                SCNAction.wait(duration: 0.16),
                hitBack,
                returnBack,
            ]),
            forKey: "hit"
        )
    }

    private func spawnParticleEffect(named effect: String, at position: SCNVector3) {
        let particles = SCNParticleSystem()
        particles.birthRate = 620
        particles.emissionDuration = 0.12
        particles.particleLifeSpan = 0.48
        particles.particleLifeSpanVariation = 0.14
        particles.particleSize = 0.16
        particles.particleSizeVariation = 0.08
        particles.particleVelocity = 4.6
        particles.particleVelocityVariation = 1.8
        particles.spreadingAngle = 86
        particles.blendMode = .additive
        particles.particleColor = particleColor(for: effect)

        let node = SCNNode()
        node.position = SCNVector3(position.x, position.y + 1.35, position.z)
        node.addParticleSystem(particles)
        scene.rootNode.addChildNode(node)
        node.runAction(
            SCNAction.sequence([
                SCNAction.wait(duration: 0.85),
                SCNAction.removeFromParentNode(),
            ])
        )
    }

    private func particleColor(for effect: String) -> UIColor {
        switch effect.lowercased() {
        case "fire", "ash":
            return UIColor(red: 1.0, green: 0.34, blue: 0.08, alpha: 1)
        case "ice", "crystal":
            return UIColor(red: 0.32, green: 0.86, blue: 1.0, alpha: 1)
        case "void":
            return UIColor(red: 0.58, green: 0.18, blue: 1.0, alpha: 1)
        case "light":
            return UIColor(red: 1.0, green: 0.90, blue: 0.38, alpha: 1)
        case "storm":
            return UIColor(red: 0.45, green: 0.72, blue: 1.0, alpha: 1)
        default:
            return UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 1)
        }
    }

    private func normalizedXZ(_ vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.z * vector.z)
        guard length > 0.001 else {
            return SCNVector3(0, 0, -1)
        }

        return SCNVector3(vector.x / length, 0, vector.z / length)
    }

    private func makeFighterNode(for stats: CharacterStats, isEnemy: Bool)
        -> SCNNode
    {
        let root = isEnemy ? enemyRootNode : playerRootNode
        root.childNodes.forEach { $0.removeFromParentNode() }

        let modelContainer = SCNNode()
        let modelNode = loadModel(
            named: stats.model,
            textureName: stats.texture
        )
        modelContainer.addChildNode(modelNode)
        root.addChildNode(modelContainer)

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

        let groundY = getGroundTopY()

        let yOffset: Float = 2
        let xOffset: Float = 2
        let zOffset: Float = 10

        if isEnemy {
            root.position = SCNVector3(-xOffset, groundY + yOffset, -zOffset)
            root.eulerAngles.y = Float.pi
        } else {
            root.position = SCNVector3(xOffset, groundY + yOffset, zOffset)
            root.eulerAngles.y = 0
        }

        return root
    }

    private func loadModel(named modelName: String, textureName: String?)
        -> SCNNode
    {
        let container = SCNNode()

        if let scene = loadModelScene(named: modelName) {
            for child in scene.rootNode.childNodes {
                container.addChildNode(child.clone())
            }
            removeModelAnimations(from: container)
            applyCharacterTextureIfNeeded(textureName, to: container)
        }

        return container
    }

    private func loadModelScene(named modelName: String) -> SCNScene? {
        SCNScene(named: "\(modelName).usdz")
            ?? SCNScene(named: "3DModel/\(modelName).usdz")
            ?? SCNScene(named: "3DModelleAnimation/\(modelName).usdz")
            ?? SCNScene(named: "\(modelName).scn")
            ?? SCNScene(named: "3DModel/\(modelName).scn")
            ?? SCNScene(named: "3DModelleAnimation/\(modelName).scn")
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

    private func applyCharacterTextureIfNeeded(
        _ textureName: String?,
        to rootNode: SCNNode
    ) {
        guard
            let textureName,
            !textureName.isEmpty,
            let image = loadTextureImage(named: textureName)
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
                material.diffuse.contents = image
                material.diffuse.wrapS = .repeat
                material.diffuse.wrapT = .repeat
                material.roughness.contents = 0.85
                material.metalness.contents = 0.0
                material.isDoubleSided = true
            }

            copiedGeometry.materials = copiedMaterials
            node.geometry = copiedGeometry
        }
    }

    private func loadTextureImage(named textureName: String) -> UIImage? {
        UIImage(named: textureName)
            ?? UIImage(named: "\(textureName).jpg")
            ?? UIImage(named: "\(textureName).png")
            ?? UIImage(named: "3DModel/\(textureName).jpg")
            ?? UIImage(named: "3DModel/\(textureName).png")
    }
}
#Preview {
    BattleSceneView(
        player: loadBattlePlayer(),
        enemy: CharacterStats(
            name: "Enemy",
            image: "1",
            model: "warriorin",
            hp: 100,
            attack: 10
        ),
        enemyHP: 0.72,
        playerAttackID: 0,
        enemyAttackID: 0,
        particleEffect: "fire",
        groundTexture: "sar_bg",
        skyboxTexture: "sar_bg"
    )
    .ignoresSafeArea()
}
