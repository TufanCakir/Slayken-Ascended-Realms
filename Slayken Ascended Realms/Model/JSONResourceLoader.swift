//
//  JSONResourceLoader.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

enum JSONResourceLoader {
    private static let cacheLock = NSLock()
    private static var memoryCache = [String: Data]()
    private static var decodedCache = [String: Any]()
    private static var bundledResourceNamesCache: [String]?

    static func loadData(resource: String) -> Data? {
        cacheLock.lock()
        let cachedData = memoryCache[resource]
        cacheLock.unlock()
        if let cachedData {
            return cachedData
        }

        if let cachedData = RemoteContentManager.cachedData(
            forResource: resource
        ) {
            cacheLock.lock()
            memoryCache[resource] = cachedData
            cacheLock.unlock()
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
        cacheLock.lock()
        memoryCache[resource] = bundledData
        cacheLock.unlock()
        return bundledData
    }

    static func load<T: Decodable>(_ type: T.Type, resource: String) -> T? {
        let cacheKey = "\(String(reflecting: T.self)):\(resource)"
        cacheLock.lock()
        let cachedValue = decodedCache[cacheKey] as? T
        cacheLock.unlock()
        if let cachedValue {
            return cachedValue
        }

        do {
            guard let data = loadData(resource: resource) else { return nil }
            let decodedValue = try JSONDecoder().decode(T.self, from: data)
            cacheLock.lock()
            decodedCache[cacheKey] = decodedValue
            cacheLock.unlock()
            return decodedValue
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
        cacheLock.lock()
        memoryCache.removeAll()
        decodedCache.removeAll()
        bundledResourceNamesCache = nil
        cacheLock.unlock()
    }

    private static func bundledResourceNames() -> [String] {
        cacheLock.lock()
        let cachedNames = bundledResourceNamesCache
        cacheLock.unlock()
        if let cachedNames {
            return cachedNames
        }

        let resourceNames =
            Bundle.main.urls(
                forResourcesWithExtension: "json",
                subdirectory: nil
            )?
            .compactMap { $0.deletingPathExtension().lastPathComponent }
            ?? []

        cacheLock.lock()
        if let bundledResourceNamesCache {
            cacheLock.unlock()
            return bundledResourceNamesCache
        }
        bundledResourceNamesCache = resourceNames
        cacheLock.unlock()
        return resourceNames
    }
}
