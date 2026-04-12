//
//  StoryLine.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import Foundation

struct StoryLine: Identifiable, Codable {
    let id: UUID
    let speaker: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case speaker, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.speaker = try container.decode(String.self, forKey: .speaker)
        self.text = try container.decode(String.self, forKey: .text)
    }
}
