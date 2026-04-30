//
//  RemoteContentManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import Foundation
import SceneKit
import UIKit

struct RemoteContentConfiguration: Codable {
    let enabled: Bool
    let manifestURL: String
}

struct RemoteContentManifest: Codable {
    let resources: [RemoteContentResource]
    let assets: [RemoteContentAsset]?
}

struct RemoteContentResource: Codable {
    let name: String
    let version: String
    let url: String
}

struct RemoteContentAsset: Codable {
    let name: String
    let version: String?
    let url: String
}

@MainActor
final class RemoteContentManager: ObservableObject {
    static let shared = RemoteContentManager()

    @Published private(set) var isRefreshing = false
    @Published private(set) var refreshProgress = 0.0
    @Published private(set) var statusText = "Live content idle"
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var lastErrorMessage: String?

    private let fileManager = FileManager.default

    func refreshContentIfNeeded() async {
        guard !isRefreshing else { return }
        guard
            let configuration = loadConfiguration(),
            configuration.enabled,
            let manifestURL = URL(string: configuration.manifestURL)
        else {
            return
        }

        isRefreshing = true
        refreshProgress = 0
        statusText = "Loading live manifest"
        defer { isRefreshing = false }

        do {
            try Self.ensureCacheDirectory()

            let (manifestData, manifestResponse) = try await URLSession.shared.data(
                from: manifestURL
            )
            try Self.validateHTTPResponse(manifestResponse)

            let manifest = try JSONDecoder().decode(
                RemoteContentManifest.self,
                from: manifestData
            )

            var versions = Self.loadCachedVersions()
            var didChangeContent = false
            let totalItems = manifest.resources.count + (manifest.assets?.count ?? 0)
            var completedItems = 0

            for resource in manifest.resources {
                guard let resourceURL = URL(string: resource.url) else { continue }
                statusText = "Checking \(resource.name).json"

                let cacheURL = try Self.cacheFileURL(forResource: resource.name)
                let hasMatchingVersion =
                    versions[resource.name] == resource.version
                    && fileManager.fileExists(atPath: cacheURL.path)

                if hasMatchingVersion {
                    completedItems += 1
                    refreshProgress = Self.progressValue(
                        completed: completedItems,
                        total: totalItems
                    )
                    continue
                }

                statusText = "Downloading \(resource.name).json"
                let (resourceData, resourceResponse) = try await URLSession.shared
                    .data(from: resourceURL)
                try Self.validateHTTPResponse(resourceResponse)

                try resourceData.write(to: cacheURL, options: .atomic)
                versions[resource.name] = resource.version
                didChangeContent = true
                completedItems += 1
                refreshProgress = Self.progressValue(
                    completed: completedItems,
                    total: totalItems
                )
            }

            for asset in manifest.assets ?? [] {
                guard let assetURL = URL(string: asset.url) else { continue }
                statusText = "Checking \(asset.name)"

                let cacheURL = try Self.assetCacheFileURL(forAssetName: asset.name)
                let versionKey = "asset:\(asset.name)"
                let hasMatchingVersion =
                    versions[versionKey] == (asset.version ?? "static")
                    && fileManager.fileExists(atPath: cacheURL.path)

                if hasMatchingVersion {
                    completedItems += 1
                    refreshProgress = Self.progressValue(
                        completed: completedItems,
                        total: totalItems
                    )
                    continue
                }

                statusText = "Downloading \(asset.name)"
                let (assetData, assetResponse) = try await URLSession.shared.data(
                    from: assetURL
                )
                try Self.validateHTTPResponse(assetResponse)

                try assetData.write(to: cacheURL, options: .atomic)
                versions[versionKey] = asset.version ?? "static"
                didChangeContent = true
                completedItems += 1
                refreshProgress = Self.progressValue(
                    completed: completedItems,
                    total: totalItems
                )
            }

            try Self.saveCachedVersions(versions)
            lastErrorMessage = nil
            refreshProgress = 1

            if didChangeContent {
                statusText = "Live content updated"
                lastRefreshDate = Date()
            } else {
                statusText = "Live content already up to date"
            }
        } catch {
            refreshProgress = 1
            statusText = "Live update failed"
            lastErrorMessage = error.localizedDescription
        }
    }

    nonisolated static func cachedData(forResource resource: String) -> Data? {
        guard let cacheURL = try? cacheFileURL(forResource: resource) else {
            return nil
        }

        return try? Data(contentsOf: cacheURL)
    }

    nonisolated static func cachedImage(named imageName: String) -> UIImage? {
        for candidate in imageCandidates(for: imageName) {
            guard let url = try? assetCacheFileURL(forAssetName: candidate) else {
                continue
            }

            if let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }

        return nil
    }

    nonisolated static func cachedScene(candidateNames: [String]) -> SCNScene? {
        for candidate in candidateNames {
            let fileName = URL(fileURLWithPath: candidate).lastPathComponent
            guard let url = try? assetCacheFileURL(forAssetName: fileName) else {
                continue
            }

            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            if let scene = try? SCNScene(url: url, options: nil) {
                return scene
            }
        }

        return nil
    }

    nonisolated static func cachedAssetURL(
        named assetName: String,
        preferredExtensions: [String] = []
    ) -> URL? {
        let candidateNames = assetCandidates(
            for: assetName,
            preferredExtensions: preferredExtensions
        )

        for candidate in candidateNames {
            guard let url = try? assetCacheFileURL(forAssetName: candidate) else {
                continue
            }

            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }

    private func loadConfiguration() -> RemoteContentConfiguration? {
        guard
            let url = Bundle.main.url(
                forResource: "remote_content_config",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            RemoteContentConfiguration.self,
            from: data
        )
    }

    private nonisolated static func validateHTTPResponse(
        _ response: URLResponse
    ) throws {
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200 ... 299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
    }

    private nonisolated static func cacheRootURL() throws -> URL {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return baseURL.appendingPathComponent(
            "RemoteContentCache",
            isDirectory: true
        )
    }

    private nonisolated static func cacheFileURL(forResource resource: String) throws
        -> URL
    {
        try cacheRootURL().appendingPathComponent("\(resource).json")
    }

    private nonisolated static func versionsFileURL() throws -> URL {
        try cacheRootURL().appendingPathComponent("resource_versions.json")
    }

    private nonisolated static func assetCacheDirectoryURL() throws -> URL {
        try cacheRootURL().appendingPathComponent("assets", isDirectory: true)
    }

    private nonisolated static func assetCacheFileURL(forAssetName assetName: String) throws
        -> URL
    {
        try assetCacheDirectoryURL().appendingPathComponent(
            URL(fileURLWithPath: assetName).lastPathComponent
        )
    }

    private nonisolated static func ensureCacheDirectory() throws {
        try FileManager.default.createDirectory(
            at: cacheRootURL(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: assetCacheDirectoryURL(),
            withIntermediateDirectories: true
        )
    }

    private nonisolated static func imageCandidates(for imageName: String) -> [String] {
        assetCandidates(
            for: imageName,
            preferredExtensions: ["png", "jpg", "jpeg", "webp"]
        )
    }

    private nonisolated static func assetCandidates(
        for assetName: String,
        preferredExtensions: [String]
    ) -> [String] {
        var candidates = [assetName]

        if !assetName.contains(".") {
            candidates.append(
                contentsOf: preferredExtensions.map { "\(assetName).\($0)" }
            )
        }

        return candidates
    }

    private nonisolated static func progressValue(
        completed: Int,
        total: Int
    ) -> Double {
        guard total > 0 else { return 1 }
        return min(1, max(0, Double(completed) / Double(total)))
    }

    private nonisolated static func loadCachedVersions() -> [String: String] {
        guard
            let versionsURL = try? versionsFileURL(),
            let data = try? Data(contentsOf: versionsURL),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }

        return decoded
    }

    private nonisolated static func saveCachedVersions(
        _ versions: [String: String]
    ) throws {
        let data = try JSONEncoder().encode(versions)
        try data.write(to: versionsFileURL(), options: .atomic)
    }
}
