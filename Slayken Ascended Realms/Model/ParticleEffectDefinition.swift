//
//  ParticleEffectDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct ParticleEffectDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double?
    let birthRate: Double?
    let emissionDuration: Double?
    let lifeSpan: Double?
    let lifeSpanVariation: Double?
    let size: Double?
    let sizeVariation: Double?
    let velocity: Double?
    let velocityVariation: Double?
    let spreadingAngle: Double?
    let yOffset: Double?
    let cleanupDelay: Double?

    var resolvedAlpha: Double { alpha ?? 1.0 }
    var resolvedBirthRate: Double { birthRate ?? 620 }
    var resolvedEmissionDuration: Double { emissionDuration ?? 0.12 }
    var resolvedLifeSpan: Double { lifeSpan ?? 0.48 }
    var resolvedLifeSpanVariation: Double { lifeSpanVariation ?? 0.14 }
    var resolvedSize: Double { size ?? 0.16 }
    var resolvedSizeVariation: Double { sizeVariation ?? 0.08 }
    var resolvedVelocity: Double { velocity ?? 4.6 }
    var resolvedVelocityVariation: Double { velocityVariation ?? 1.8 }
    var resolvedSpreadingAngle: Double { spreadingAngle ?? 86 }
    var resolvedYOffset: Double { yOffset ?? 1.35 }
    var resolvedCleanupDelay: Double { cleanupDelay ?? 0.85 }
}

func loadParticleEffects() -> [ParticleEffectDefinition] {
    JSONResourceLoader.loadArray(
        ParticleEffectDefinition.self,
        resource: "particle_effects"
    )
}
