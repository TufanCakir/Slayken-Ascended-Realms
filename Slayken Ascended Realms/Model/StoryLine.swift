//
//  StoryLine.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct StoryLine: Identifiable, Codable {
    let id: UUID
    let speaker: String
    let image: String?
    let text: String

    enum CodingKeys: String, CodingKey {
        case speaker
        case image
        case text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.speaker = try container.decode(String.self, forKey: .speaker)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.text = try container.decode(String.self, forKey: .text)
    }
}
