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

    init(player: CharacterStats, enemy: CharacterStats) {
        self.playerStats = player
        self.enemyStats = enemy
    }

    func updateEnemyHP(_ value: CGFloat) {
        let safe = max(0, min(1, value))
        enemyHPNode?.scale.x = Float(safe)
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
        camera.fieldOfView = 60

        cameraNode.camera = camera

        // 🔥 Seitlich + oben + zurück
        cameraNode.position = SCNVector3(15, 5, 15)

        // 🔥 Auf Mittelpunkt zwischen beiden schauen
        cameraNode.look(at: SCNVector3(0, 0, 0))

        return cameraNode
    }
    
    private func makeHPBarNode() -> SCNNode {
        let container = SCNNode()

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        container.constraints = [billboard]

        // Hintergrund
        let backgroundPlane = SCNPlane(width: 1.2, height: 0.12)
        let backgroundMaterial = SCNMaterial()
        backgroundMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.55)
        backgroundMaterial.isDoubleSided = true
        backgroundPlane.materials = [backgroundMaterial]

        let backgroundNode = SCNNode(geometry: backgroundPlane)
        container.addChildNode(backgroundNode)

        // Rote Füllung
        let fillPlane = SCNPlane(width: 1.1, height: 0.08)
        let fillMaterial = SCNMaterial()
        fillMaterial.diffuse.contents = UIColor.systemRed
        fillMaterial.isDoubleSided = true
        fillPlane.materials = [fillMaterial]

        let fillNode = SCNNode(geometry: fillPlane)

        // Wichtig: leicht vor den Hintergrund
        fillNode.pivot = SCNMatrix4MakeTranslation(-0.55, 0, 0)
        fillNode.position = SCNVector3Zero // ✅ DAS REICHT

        container.addChildNode(fillNode)

        // Rahmen
        let borderPlane = SCNPlane(width: 3, height: 0.34)
        let borderMaterial = SCNMaterial()
        borderMaterial.diffuse.contents = UIColor.clear
        borderMaterial.emission.contents = UIColor.white.withAlphaComponent(0.2)
        borderMaterial.isDoubleSided = true
        borderPlane.materials = [borderMaterial]

        let borderNode = SCNNode(geometry: borderPlane)
        borderNode.position = SCNVector3(1, 3, 1.2)
        container.addChildNode(borderNode)

        enemyHPNode = fillNode
        return container
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

    private func configureGroundMaterial(_ material: SCNMaterial, textureName: String) {
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

    private func makeFighterNode(for stats: CharacterStats, isEnemy: Bool) -> SCNNode {
        let root = isEnemy ? enemyRootNode : playerRootNode
        root.childNodes.forEach { $0.removeFromParentNode() }

        let modelContainer = SCNNode()
        let modelNode = loadModel(named: stats.model)
        modelContainer.addChildNode(modelNode)
        root.addChildNode(modelContainer)

        let bounds = modelNode.boundingBox

        let centerX = (bounds.min.x + bounds.max.x) * 0.5
        let centerZ = (bounds.min.z + bounds.max.z) * 0.5

        modelNode.pivot = SCNMatrix4MakeTranslation(centerX, bounds.min.y, centerZ)

        let height = max(bounds.max.y - bounds.min.y, 0.01)
        let scale: Float = 4.0 / height
        modelContainer.scale = SCNVector3(scale, scale, scale)

        modelContainer.eulerAngles = SCNVector3(-Float.pi / 2, Float.pi / 2, 0)

        // ✅ HP BAR RICHTIG PLATZIEREN
        if isEnemy {
            let hpNode = makeHPBarNode()

            let topY = (bounds.max.y - bounds.min.y) * scale
            hpNode.position = SCNVector3(0, topY * 0.8, 0)

            // 🔥 WICHTIG: an modelContainer hängen
            modelContainer.addChildNode(hpNode)
        }

        let groundY = getGroundTopY()

        let yOffset: Float = 2
        let xOffset: Float = 8
        let zOffset: Float = 5

        if isEnemy {
            root.position = SCNVector3(-xOffset, groundY + yOffset, -zOffset)
            root.eulerAngles.y = Float.pi
        } else {
            root.position = SCNVector3(xOffset, groundY + yOffset, zOffset)
            root.eulerAngles.y = 0
        }

        return root
    }

    private func loadModel(named modelName: String) -> SCNNode {
        let container = SCNNode()

        if let scene = SCNScene(named: "\(modelName).usdz")
            ?? SCNScene(named: "\(modelName).scn")
        {
            for child in scene.rootNode.childNodes {
                container.addChildNode(child.clone())
            }
        } else {
            let fallback = SCNCapsule(capRadius: 1, height: 3)
            fallback.firstMaterial?.diffuse.contents = UIColor.systemGray
            container.geometry = fallback
        }

        return container
    }
}
#Preview {
    BattleSceneView(
        player: loadPlayer(),
        enemy: CharacterStats(
            name: "Enemy",
            image: "character1",
            model: "warrior",
            hp: 100,
            attack: 10
        ),
        enemyHP: 0.72,
        groundTexture: "sar_bg",
        skyboxTexture: "sar_bg"
    )
    .ignoresSafeArea()
}
