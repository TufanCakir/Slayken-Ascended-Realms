//
//  JSONResourceLoader.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum JSONResourceLoader {
    private static var memoryCache = [String: Data]()
    private static var bundledResourceNamesCache: [String]?

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

    static func loadMergedIdentifiableArrays<T: Decodable & Identifiable>(
        _ type: T.Type,
        baseResources: [String],
        autoDiscoveredWhere predicate: (String) -> Bool,
        sort: ((T, T) -> Bool)? = nil
    ) -> [T] where T.ID: Hashable {
        let discoveredResources = Set(
            RemoteContentManager.cachedResourceNames().filter(predicate)
                + bundledResourceNames().filter(predicate)
        )
        .sorted()

        var orderedResources = [String]()
        var seenResources = Set<String>()

        for resourceName in baseResources + discoveredResources {
            if seenResources.insert(resourceName).inserted {
                orderedResources.append(resourceName)
            }
        }

        var orderedIDs = [T.ID]()
        var valuesByID = [T.ID: T]()

        for resourceName in orderedResources {
            let items = loadArray(type, resource: resourceName)

            for item in items {
                if valuesByID.updateValue(item, forKey: item.id) == nil {
                    orderedIDs.append(item.id)
                }
            }
        }

        let mergedItems = orderedIDs.compactMap { valuesByID[$0] }
        guard let sort else { return mergedItems }
        return mergedItems.sorted(by: sort)
    }

    static func invalidateCache() {
        memoryCache.removeAll()
        bundledResourceNamesCache = nil
    }

    private static func bundledResourceNames() -> [String] {
        if let bundledResourceNamesCache {
            return bundledResourceNamesCache
        }

        let resourceNames =
            Bundle.main.urls(
                forResourcesWithExtension: "json",
                subdirectory: nil
            )?
            .compactMap { $0.deletingPathExtension().lastPathComponent }
            ?? []
        bundledResourceNamesCache = resourceNames
        return resourceNames
    }
}
