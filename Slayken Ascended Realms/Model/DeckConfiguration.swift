//
//  DeckConfiguration.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct DeckConfiguration: Codable, Equatable {
    let slotCount: Int

    var resolvedSlotCount: Int {
        max(1, slotCount)
    }
}

func loadDeckConfiguration() -> DeckConfiguration {
    let fallback = DeckConfiguration(slotCount: 4)

    guard let data = JSONResourceLoader.loadData(resource: "deck_config") else {
        return fallback
    }

    let decoder = JSONDecoder()

    if let configuration = try? decoder.decode(
        DeckConfiguration.self,
        from: data
    ) {
        return configuration
    }

    if let configurations = try? decoder.decode(
        [DeckConfiguration].self,
        from: data
    ),
        let configuration = configurations.first
    {
        return configuration
    }

    return fallback
}
