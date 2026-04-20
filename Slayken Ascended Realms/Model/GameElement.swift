//
//  GameElement.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

enum GameElement: String, CaseIterable {
    case fire
    case water
    case plant
    case ice
    case storm
    case ash
    case light
    case dark
    case void
    case neutral

    init(_ rawValue: String?) {
        let normalized =
            rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        switch normalized {
        case "fire", "feuer":
            self = .fire
        case "water", "wasser", "ice", "crystal":
            self =
                normalized == "ice" || normalized == "crystal" ? .ice : .water
        case "plant", "nature", "pflanze", "grass":
            self = .plant
        case "storm", "thunder", "lightning", "blitz":
            self = .storm
        case "ash":
            self = .ash
        case "light", "licht":
            self = .light
        case "dark", "darkness", "dunkel", "dunkelheit", "void":
            self = normalized == "void" ? .void : .dark
        default:
            self = .neutral
        }
    }

    var displayName: String {
        switch self {
        case .fire: return "Fire"
        case .water: return "Water"
        case .plant: return "Plant"
        case .ice: return "Ice"
        case .storm: return "Storm"
        case .ash: return "Ash"
        case .light: return "Light"
        case .dark: return "Dark"
        case .void: return "Void"
        case .neutral: return "Neutral"
        }
    }

    var color: Color {
        switch self {
        case .fire: return Color(red: 0.95, green: 0.25, blue: 0.10)
        case .water: return Color(red: 0.12, green: 0.46, blue: 0.95)
        case .plant: return Color(red: 0.20, green: 0.72, blue: 0.28)
        case .ice: return Color(red: 0.42, green: 0.88, blue: 0.98)
        case .storm: return Color(red: 0.58, green: 0.66, blue: 1.00)
        case .ash: return Color(red: 0.62, green: 0.26, blue: 0.16)
        case .light: return Color(red: 1.00, green: 0.86, blue: 0.28)
        case .dark: return Color(red: 0.38, green: 0.18, blue: 0.72)
        case .void: return Color(red: 0.56, green: 0.18, blue: 0.95)
        case .neutral: return Color.gray
        }
    }

    func multiplier(against defender: GameElement) -> Double {
        guard self != .neutral, defender != .neutral else { return 1.0 }
        if self == .light || self == .dark || self == .void { return 1.18 }
        if defender == .light || defender == .dark || defender == .void {
            return 1.0
        }

        switch (self, defender) {
        case (.fire, .plant), (.plant, .water), (.water, .fire), (.ice, .plant),
            (.storm, .water), (.ash, .ice):
            return 1.35
        case (.fire, .water), (.plant, .fire), (.water, .plant), (.plant, .ice),
            (.water, .storm), (.ice, .ash):
            return 0.72
        default:
            return 1.0
        }
    }
}
