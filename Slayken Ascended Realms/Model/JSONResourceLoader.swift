//
//  JSONResourceLoader.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum JSONResourceLoader {
    static func loadData(resource: String) -> Data? {
        if let cachedData = RemoteContentManager.cachedData(forResource: resource) {
            return cachedData
        }

        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json"
            )
        else {
            return nil
        }

        return try? Data(contentsOf: url)
    }

    static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        do {
            guard let data = loadData(resource: resource) else { return nil }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    static func loadArray<T: Decodable>(_ type: T.Type, resource: String) -> [T]
    {
        load([T].self, resource: resource) ?? []
    }
}
