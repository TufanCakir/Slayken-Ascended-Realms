//
//  NewsItemDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct NewsItemDefinition: Codable, Identifiable, Equatable {
    let id: String
    let category: String
    let title: String
    let subtitle: String
    let image: String
    let date: String
    let tags: [String]
    let body: String
}

func loadNewsItems() -> [NewsItemDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        NewsItemDefinition.self,
        baseResources: ["news_items"],
        autoDiscoveredWhere: {
            $0.hasPrefix("news_items_") || $0.hasPrefix("news_")
        }
    )
}
