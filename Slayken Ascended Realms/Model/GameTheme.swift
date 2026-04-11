//
//  GameTheme.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import SwiftUI

struct GameTheme: Identifiable, Codable {
    let id: Int
    let name: String

    let primary: ColorData
    let secondary: ColorData
    let accent: ColorData
    let glow: ColorData
}

struct ColorData: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double

    var color: Color {
        Color(red: r, green: g, blue: b).opacity(a)
    }
}
