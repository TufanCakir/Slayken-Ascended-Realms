//
//  GameSceneView.swift
//  test
//

import SceneKit
import SwiftUI
import UIKit

struct GameSceneView: UIViewRepresentable {
    let player: CharacterStats
    let joystickVector: SIMD2<Float>
    let groundTexture: String
    let skyboxTexture: String

    func makeCoordinator() -> SceneCoordinator {
        SceneCoordinator(player: player)
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
    private let player: CharacterStats
    
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

    init(player: CharacterStats) {
        self.player = player
    }
    
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
        camera.fieldOfView = 50

        cameraNode.camera = camera

        // 🔥 SIDE VIEW (leicht schräg von rechts)
        cameraNode.position = SCNVector3(0, 5, 20)
        cameraNode.look(at: SCNVector3(0, 0, 0))

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
    
    private var currentAnimation: String = ""
    private let playerHeightOffset: Float = 1

    private struct PlayerAnimation {
        let node: SCNNode
        let key: String
        let animation: CAAnimation
    }
    
    private func playAnimation(named name: String) {
        guard currentAnimation != name else { return }
        currentAnimation = name

        stopStoredAnimations()

        guard !animations.isEmpty else {
            print("Character animation not found for: \(name). No animations loaded.")
            return
        }

        for entry in animations {
            entry.node.addAnimation(entry.animation, forKey: entry.key)
        }

        print("Character animation started: \(name), entries=\(animations.count)")
    }

    private func stopPlayerAnimation() {
        guard !currentAnimation.isEmpty else { return }
        currentAnimation = ""
        stopStoredAnimations()
        print("Character animations stopped")
    }

    private func stopStoredAnimations() {
        for entry in animations {
            entry.node.removeAnimation(forKey: entry.key, blendOutDuration: 0.15)
        }
        playerNode.removeAllAnimations()
        playerVisualNode.removeAllAnimations()
    }
    
    private func getGroundTopY() -> Float {
        guard let ground = groundNode,
              let box = ground.geometry as? SCNBox else { return 0 }
        return ground.position.y + Float(box.height) * 0.5
    }
    
    private func makePlayer() -> SCNNode {
        // 1. Model laden
        if let modelScene = SCNScene(named: "\(player.model).usdz") {
            for child in modelScene.rootNode.childNodes {
                playerVisualNode.addChildNode(child.clone())
            }
            applyCharacterTextureIfNeeded(player.texture, to: playerVisualNode)
        } else {
            let fallback = SCNSphere(radius: 1)
            fallback.firstMaterial?.diffuse.contents = UIColor.white
            playerVisualNode.geometry = fallback
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
        
        playerVisualNode.scale = SCNVector3(scale, scale, scale)

        // 6. In Parent einhängen
        playerNode.addChildNode(playerVisualNode)

        // 7. EXAKT auf Boden setzen
        playerNode.position = SCNVector3(0, getGroundTopY() + playerHeightOffset, 0)
      
        loadAnimations()

        return playerNode
    }

    private func applyCharacterTextureIfNeeded(_ textureName: String?, to rootNode: SCNNode) {
        guard
            let textureName,
            !textureName.isEmpty,
            let image = loadTextureImage(named: textureName)
        else { return }

        rootNode.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }

            let copiedGeometry = geometry.copy() as? SCNGeometry ?? geometry
            let copiedMaterials = copiedGeometry.materials.isEmpty
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

        if magnitude > 0.1 {
            playAnimation(named: "move")
        } else {
            stopPlayerAnimation()
        }

        guard magnitude > 0.08 else { return }

        let direction = simd_normalize(simd_float3(input.x, 0, -input.y))

        let speed: Float = 25
        let distance = min(magnitude, 1) * speed * deltaTime

        var newPosition = playerNode.simdPosition + direction * distance
        newPosition.y = getGroundTopY() + playerHeightOffset
        newPosition = clampToGroundBounds(newPosition)

        playerNode.simdPosition = newPosition
        playerNode.eulerAngles.y = atan2(direction.x, direction.z)
    }
    
    private func loadAnimations() {
        animations.removeAll()
        print("Scanning character animations...")

        playerVisualNode.enumerateChildNodes { node, _ in
            let nodeName = node.name ?? "unnamed node"

            for key in node.animationKeys {
                if let anim = node.animation(forKey: key) {
                    let animation = (anim.copy() as? CAAnimation) ?? anim
                    animation.repeatCount = .infinity
                    animation.fadeInDuration = 0.2
                    animation.fadeOutDuration = 0.2
                    animations.append(PlayerAnimation(node: node, key: key, animation: animation))
                    node.removeAnimation(forKey: key)
                    print("Found character animation: key=\(key), node=\(nodeName), duration=\(animation.duration)")
                }
            }
        }

        if animations.isEmpty {
            print("No character animations found")
        } else {
            let animationNames = animations.map(\.key).sorted()
            print("Character animations loaded: \(animationNames)")
        }
    }
    
    private var animations: [PlayerAnimation] = []
    
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
#Preview {
    GameSceneView(
        player: loadGamePlayer(),
        joystickVector: .zero,
        groundTexture: TextureNames.ground,
        skyboxTexture: TextureNames.skybox
    )
    .ignoresSafeArea()
}
