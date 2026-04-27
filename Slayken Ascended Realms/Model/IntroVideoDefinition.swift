//
//  IntroVideoDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct IntroVideoDefinition: Codable, Identifiable {
    let id: String
    let flow: String?
    let order: Int?
    let title: String
    let text: String?
    let video: String
}

func loadIntroVideoDefinitions() -> [IntroVideoDefinition] {
    JSONResourceLoader.loadArray(
        IntroVideoDefinition.self,
        resource: "intro_videos"
    )
}
