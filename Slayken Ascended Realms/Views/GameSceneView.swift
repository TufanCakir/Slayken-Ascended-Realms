//
//  GameSceneView.swift
//  test
//

import SceneKit
import SwiftUI
import UIKit

struct GameSceneView: UIViewRepresentable {
    let joystickVector: SIMD2<Float>
    let groundTexture: String
    let skyboxTexture: String

    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = context.coordinator.scene
        view.backgroundColor = .black
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.isPlaying = true
        view.preferredFramesPerSecond = 60
        
        context.coordinator.start()
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.joystickVector = joystickVector
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
    
    private let playerNode = SCNNode()
    private let playerVisualNode = SCNNode()
    private let cameraNode = SCNNode()
    private var groundNode: SCNNode?
    private var groundBox: SCNBox?
    
    private var currentGroundTexture = TextureNames.ground
    private var currentSkyboxTexture = TextureNames.skybox
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    
    var joystickVector: SIMD2<Float> = .zero
    
    func start() {
        guard displayLink == nil else { return }
        
        setupScene()
        
        let link = CADisplayLink(target: self, selector: #selector(stepFrame(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private func setupScene() {
        guard scene.rootNode.childNodes.isEmpty else { return }
        
        scene.rootNode.addChildNode(makeCamera())
        scene.rootNode.addChildNode(makeLights())
        scene.rootNode.addChildNode(makeGround())
        scene.rootNode.addChildNode(makePlayer())
        
        scene.background.contents = UIImage(named: "sar_bg")
        scene.lightingEnvironment.contents = UIImage(named: "sar_bg")
    }
    
    func updateTextures(ground: String, skybox: String) {
        currentGroundTexture = ground
        currentSkyboxTexture = skybox

        applyGroundTexture(named: currentGroundTexture)

        scene.background.contents = UIImage(named: currentSkyboxTexture)
        scene.lightingEnvironment.contents = UIImage(named: currentSkyboxTexture)
    }
    
    private func makeCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 100   // 🔥 mehr Sichtfeld

        cameraNode.camera = camera

        // 🔥 deutlich weiter weg + höher
        cameraNode.position = SCNVector3(0, 40, 60)

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
        directional.castsShadow = true
        directional.shadowMode = .deferred
        directional.shadowRadius = 6
        directional.shadowSampleCount = 16
        directional.shadowColor = UIColor.black.withAlphaComponent(0.35)
        
        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-0.8, 0.5, 0)
        rig.addChildNode(directionalNode)
        
        return rig
    }
    
    private func getGroundTopY() -> Float {
        guard let ground = groundNode,
              let box = ground.geometry as? SCNBox else { return 0 }
        return ground.position.y + Float(box.height) * 0.5
    }
    
    private func makePlayer() -> SCNNode {
        if let modelScene = SCNScene(named: "riven.usdz") {
            for child in modelScene.rootNode.childNodes {
                playerVisualNode.addChildNode(child.clone())
            }
        } else {
            let fallback = SCNSphere(radius: 1)
            fallback.firstMaterial?.diffuse.contents = UIColor.white
            playerVisualNode.geometry = fallback
        }
        
        let bounds = playerVisualNode.boundingBox
        let centerX = (bounds.min.x + bounds.max.x) * 0.5
        let centerZ = (bounds.min.z + bounds.max.z) * 0.5
        playerVisualNode.pivot = SCNMatrix4MakeTranslation(centerX, bounds.min.y, centerZ)
        
        let height = max(bounds.max.y - bounds.min.y, 0.01)
        let scale = 3.0 / height
        playerVisualNode.scale = SCNVector3(scale, scale, scale)
        
        // USDZ assets are often authored in Z-up space. Keep movement on the parent node
        // and apply the orientation correction only to the visual node.
        playerVisualNode.eulerAngles.x = -.pi / 2
        playerNode.addChildNode(playerVisualNode)
        alignPlayerToGround()
        playerNode.position = SCNVector3(0, 0, 0)
        return playerNode
    }
    
    private func alignPlayerToGround() {
        let bounds = playerNode.boundingBox
        let bottomOffset = bounds.min.y
        
        guard bottomOffset.isFinite else { return }
        playerVisualNode.position.y -= bottomOffset
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
        let input = joystickVector
        let magnitude = simd_length(input)
        guard magnitude > 0.08 else { return }
        
        let direction = simd_normalize(simd_float3(input.x, 0, -input.y))
        
        // ✅ EINMAL sauber berechnen
        let speed: Float = 15
        let distance = min(magnitude, 1) * speed * deltaTime
        
        var newPosition = playerNode.simdPosition + direction * distance
        
        // ✅ Bodenhöhe
        newPosition.y = getGroundTopY()
        
        // ✅ Grenzen (jetzt richtig genutzt)
        newPosition = clampToGroundBounds(newPosition)
        
        playerNode.simdPosition = newPosition
        playerNode.eulerAngles.y = atan2(direction.x, direction.z)
    }
    
    private func clampToGroundBounds(_ position: simd_float3) -> simd_float3 {
        guard let ground = groundNode,
              let box = ground.geometry as? SCNBox else {
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
        let offset = SCNVector3(0, 25, 45) // 🔥 Höhe + Abstand

        let targetPosition = SCNVector3(
            playerNode.position.x + offset.x,
            playerNode.position.y + offset.y,
            playerNode.position.z + offset.z
        )

        let strength = min(deltaTime * 3, 1)

        cameraNode.position = SCNVector3(
            cameraNode.position.x + (targetPosition.x - cameraNode.position.x) * strength,
            cameraNode.position.y + (targetPosition.y - cameraNode.position.y) * strength,
            cameraNode.position.z + (targetPosition.z - cameraNode.position.z) * strength
        )

        // 🔥 immer auf Spieler schauen (leicht nach unten)
        cameraNode.look(at: SCNVector3(
            playerNode.position.x,
            playerNode.position.y,
            playerNode.position.z
        ))
    }
}

private enum TextureNames {
    static let ground = "sar_bg"
    static let skybox = "sar_bg"
}
