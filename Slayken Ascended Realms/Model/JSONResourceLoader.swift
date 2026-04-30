//
//  JSONResourceLoader.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum JSONResourceLoader {
    private static var memoryCache = [String: Data]()

    static func loadData(resource: String) -> Data? {
        if let cachedData = memoryCache[resource] {
            return cachedData
        }

        if let cachedData = RemoteContentManager.cachedData(
            forResource: resource
        ) {
            memoryCache[resource] = cachedData
            return cachedData
        }

        guard
            let url = Bundle.main.url(
                forResource: resource,
                withExtension: "json"
            )
        else {
            RemoteContentManager.logError(
                "Missing bundled JSON resource \(resource).json"
            )
            return nil
        }

        RemoteContentManager.logInfo(
            "Falling back to bundled JSON resource \(resource).json"
        )
        guard let bundledData = try? Data(contentsOf: url) else {
            return nil
        }
        memoryCache[resource] = bundledData
        return bundledData
    }

    static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        do {
            guard let data = loadData(resource: resource) else { return nil }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            RemoteContentManager.logError(
                "Failed decoding \(resource).json: \(error.localizedDescription)"
            )
            return nil
        }
    }

    static func loadArray<T: Decodable>(_ type: T.Type, resource: String) -> [T]
    {
        load([T].self, resource: resource) ?? []
    }

    static func invalidateCache() {
        memoryCache.removeAll()
    }
}
