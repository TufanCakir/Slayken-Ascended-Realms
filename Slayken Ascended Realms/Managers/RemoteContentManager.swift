//
//  RemoteContentManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import Foundation
import OSLog
import SceneKit
import UIKit

enum RemoteContentError: LocalizedError {
    case invalidHTTPStatusCode(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidHTTPStatusCode(let statusCode, let url):
            return "HTTP \(statusCode) for \(url)"
        }
    }
}

struct RemoteContentConfiguration: Codable {
    let enabled: Bool
    let manifestURL: String
}

struct RemoteContentManifest: Codable {
    let contentVersion: Int?
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

struct RemoteContentStartupPlan {
    let pendingResourceCount: Int
    let pendingAssetCount: Int
    let estimatedDownloadBytes: Int64

    var totalPendingCount: Int {
        pendingResourceCount + pendingAssetCount
    }

    var formattedEstimatedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: estimatedDownloadBytes)
    }
}

enum RemoteContentRefreshMode {
    case bootstrap
    case fullPreload
}

private enum RemoteAssetMemoryCache {
    nonisolated(unsafe) static let imageCache = NSCache<NSString, UIImage>()
    nonisolated(unsafe) static let sceneCache = NSCache<NSString, SCNScene>()
}

@MainActor
final class RemoteContentManager: ObservableObject {
    static let shared = RemoteContentManager()
    private nonisolated static let installedContentVersionKey =
        "installedRemoteContentVersion"
    private nonisolated static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SlaykenAscendedRealms",
        category: "RemoteContent"
    )

    @Published private(set) var isRefreshing = false
    @Published private(set) var refreshProgress = 0.0
    @Published private(set) var statusText = "Live content idle"
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var hasCompletedInitialRefresh = false
    @Published private(set) var isPreparingStartupPlan = false
    @Published private(set) var startupPlan: RemoteContentStartupPlan?
    @Published private(set) var requiresMandatoryUpdate = false
    @Published private(set) var startupReloadRequired = false
    @Published private(set) var startupFailureMessage: String?
    @Published private(set) var isBackgroundPreloading = false
    @Published private(set) var backgroundPreloadProgress = 0.0
    @Published private(set) var backgroundStatusText = "Background preload idle"

    private let fileManager = FileManager.default
    private var cachedManifest: RemoteContentManifest?
    private var assetDownloadTasks = [String: Task<Void, Never>]()
    private var backgroundPreloadTask: Task<Void, Never>?

    private let progressUpdateThreshold = 0.01

    nonisolated static func logDebug(_ message: String) {
        logger.debug("\(message)")
    }

    nonisolated static func logInfo(_ message: String) {
        logger.info("\(message)")
    }

    nonisolated static func logWarning(_ message: String) {
        logger.warning("\(message)")
    }

    nonisolated static func logError(_ message: String) {
        logger.error("\(message)")
    }

    func prepareStartupPlanIfNeeded() async {
        guard !isPreparingStartupPlan else { return }
        guard startupPlan == nil else { return }

        isPreparingStartupPlan = true
        startupReloadRequired = false
        startupFailureMessage = nil
        setStatusText("Preparing preload plan")
        defer { isPreparingStartupPlan = false }

        do {
            try Self.ensureCacheDirectory()
            let manifest = try await fetchManifest()
            let versions = await Self.loadCachedVersions()
            let installedContentVersion = Self.installedContentVersion()
            startupPlan = buildStartupPlan(
                manifest: manifest,
                versions: versions
            )
            requiresMandatoryUpdate = Self.requiresMandatoryUpdate(
                manifestVersion: manifest.contentVersion,
                installedVersion: installedContentVersion
            )
            setStatusText(
                requiresMandatoryUpdate
                    ? "Neues Inhalts-Update erforderlich"
                    : "Tap to choose preload mode"
            )
            lastErrorMessage = nil
            startupFailureMessage = nil
            startupReloadRequired = false
        } catch {
            setStatusText("Failed to prepare preload plan")
            startupFailureMessage =
                "Download-Plan konnte nicht geladen werden. Bitte Verbindung prüfen und erneut laden."
            startupReloadRequired = true
            lastErrorMessage = error.localizedDescription
            Self.logger.error(
                "Failed to prepare startup plan: \(error.localizedDescription)"
            )
        }
    }

    func retryStartupRefreshPreparation() async {
        cachedManifest = nil
        startupPlan = nil
        startupReloadRequired = false
        startupFailureMessage = nil
        lastErrorMessage = nil
        hasCompletedInitialRefresh = false
        setRefreshProgress(0, force: true)
        await prepareStartupPlanIfNeeded()
    }

    func refreshContentIfNeeded(mode: RemoteContentRefreshMode) async -> Bool {
        guard !isRefreshing else { return false }

        isRefreshing = true
        startupReloadRequired = false
        startupFailureMessage = nil
        lastErrorMessage = nil
        setRefreshProgress(0, force: true)
        setStatusText(
            mode == .fullPreload
                ? "Loading live manifest"
                : "Loading core game data and visuals"
        )
        defer {
            isRefreshing = false
        }

        do {
            try Self.ensureCacheDirectory()

            let manifest = try await fetchManifest()
            var versions = await Self.loadCachedVersions()
            var didChangeContent = false
            var assetsToProcess = [RemoteContentAsset]()
            var totalItems = manifest.resources.count
            var completedItems = 0
            var failedItems = [String]()

            for resource in manifest.resources {
                setStatusText("Checking \(resource.name).json")

                let result = await processResource(
                    resource,
                    versions: &versions
                )

                if result.failedName != nil {
                    failedItems.append(result.failedName!)
                }
                if result.didChangeContent {
                    didChangeContent = true
                }

                completedItems += 1
                setRefreshProgress(
                    Self.progressValue(
                        completed: completedItems,
                        total: totalItems
                    )
                )
            }

            assetsToProcess = assetsForStartup(
                from: manifest,
                mode: mode
            )
            totalItems = manifest.resources.count + assetsToProcess.count
            setRefreshProgress(
                Self.progressValue(
                    completed: completedItems,
                    total: totalItems
                )
            )

            for asset in assetsToProcess {
                setStatusText("Checking \(asset.name)")

                let result = await processAsset(
                    asset,
                    versions: &versions,
                    updatePublishedProgress: false
                )

                if result.failedName != nil {
                    failedItems.append(result.failedName!)
                }
                if result.didChangeContent {
                    didChangeContent = true
                }

                completedItems += 1
                setRefreshProgress(
                    Self.progressValue(
                        completed: completedItems,
                        total: totalItems
                    )
                )
            }

            try await Self.saveCachedVersions(versions)
            JSONResourceLoader.invalidateCache()
            setRefreshProgress(1, force: true)
            startupPlan = buildStartupPlan(
                manifest: manifest,
                versions: versions
            )

            if !failedItems.isEmpty {
                requiresMandatoryUpdate = true
                hasCompletedInitialRefresh = false
                startupReloadRequired = true
                setStatusText(
                    mode == .fullPreload
                        ? "Live update interrupted"
                        : "Core content load interrupted"
                )
                let failureSummary =
                    "Download unvollständig. Bitte bei stabiler Verbindung alles neu laden."
                startupFailureMessage = failureSummary
                lastErrorMessage =
                    "\(failureSummary) Fehlende Inhalte: \(failedItems.prefix(5).joined(separator: ", "))"
                lastRefreshDate = Date()
                Self.logger.error(
                    "Remote refresh completed with \(failedItems.count) failed item(s): \(failedItems.joined(separator: ", "))"
                )
                return false
            } else {
                lastErrorMessage = nil
            }

            if didChangeContent && failedItems.isEmpty {
                Self.saveInstalledContentVersion(manifest.contentVersion)
                requiresMandatoryUpdate = false
                hasCompletedInitialRefresh = true
                setStatusText(
                    mode == .fullPreload
                        ? "Live content updated"
                        : "Core content and visuals ready"
                )
                lastRefreshDate = Date()
                Self.logger.info("Remote refresh completed with updates.")
            } else if failedItems.isEmpty {
                Self.saveInstalledContentVersion(manifest.contentVersion)
                requiresMandatoryUpdate = false
                hasCompletedInitialRefresh = true
                setStatusText(
                    mode == .fullPreload
                        ? "Live content already up to date"
                        : "Core content and visuals already cached"
                )
                Self.logger.info(
                    "Remote refresh completed. Cache already up to date."
                )
            }
            return true
        } catch {
            setRefreshProgress(1, force: true)
            requiresMandatoryUpdate = true
            hasCompletedInitialRefresh = false
            startupReloadRequired = true
            setStatusText(
                mode == .fullPreload
                    ? "Live update failed"
                    : "Core content load failed"
            )
            startupFailureMessage =
                "Verbindung unterbrochen oder Download fehlgeschlagen. Bitte alles erneut laden."
            lastErrorMessage = error.localizedDescription
            Self.logger.error(
                "Remote refresh failed: \(error.localizedDescription)"
            )
            return false
        }
    }

    func startBackgroundPreloadIfNeeded() {
        guard !isBackgroundPreloading else { return }

        backgroundPreloadTask?.cancel()
        backgroundPreloadTask = Task { [weak self] in
            guard let self else { return }
            await self.runBackgroundPreload()
        }
    }

    func downloadAssetIfNeeded(named assetName: String) async {
        let candidateNames = Self.assetCandidates(
            for: assetName,
            preferredExtensions: [
                "png", "jpg", "jpeg", "webp", "usdz", "mp4", "mp3",
            ]
        )

        if candidateNames.contains(where: { hasCachedAsset(named: $0) }) {
            return
        }

        let taskKey = candidateNames.first ?? assetName
        if let existingTask = assetDownloadTasks[taskKey] {
            await existingTask.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runOnDemandAssetDownload(
                requestedName: assetName,
                candidateNames: candidateNames
            )
        }

        assetDownloadTasks[taskKey] = task
        await task.value
        assetDownloadTasks[taskKey] = nil
    }

    nonisolated static func cachedData(forResource resource: String) -> Data? {
        guard let cacheURL = try? cacheFileURL(forResource: resource) else {
            logger.error(
                "Could not build cache path for resource \(resource).json"
            )
            return nil
        }

        guard let data = try? Data(contentsOf: cacheURL) else {
            logger.debug(
                "No cached JSON found for \(resource).json at \(cacheURL.path)"
            )
            return nil
        }

        return data
    }

    nonisolated static func cachedImage(named imageName: String) -> UIImage? {
        guard !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        for candidate in imageCandidates(for: imageName) {
            if let cachedImage = RemoteAssetMemoryCache.imageCache.object(
                forKey: candidate as NSString
            ) {
                return cachedImage
            }

            guard let url = try? assetCacheFileURL(forAssetName: candidate)
            else {
                continue
            }

            if let image = UIImage(contentsOfFile: url.path) {
                RemoteAssetMemoryCache.imageCache.setObject(
                    image,
                    forKey: candidate as NSString
                )
                return image
            }
        }

        return nil
    }

    nonisolated static func memoryCachedImage(named imageName: String)
        -> UIImage?
    {
        guard !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        for candidate in imageCandidates(for: imageName) {
            if let cachedImage = RemoteAssetMemoryCache.imageCache.object(
                forKey: candidate as NSString
            ) {
                return cachedImage
            }
        }

        return nil
    }

    nonisolated static func cachedOrBundledImage(named imageName: String)
        -> UIImage?
    {
        guard !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return cachedImage(named: imageName)
    }

    nonisolated static func loadCachedOrBundledImage(named imageName: String)
        async -> UIImage?
    {
        await Task.detached(priority: .utility) {
            cachedOrBundledImage(named: imageName)
        }.value
    }

    nonisolated static func hasCachedOrBundledImage(named imageName: String)
        -> Bool
    {
        guard !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return false
        }

        for candidate in imageCandidates(for: imageName) {
            if RemoteAssetMemoryCache.imageCache.object(
                forKey: candidate as NSString
            ) != nil {
                return true
            }

            guard let url = try? assetCacheFileURL(forAssetName: candidate)
            else {
                continue
            }

            if FileManager.default.fileExists(atPath: url.path) {
                return true
            }
        }

        return false
    }

    nonisolated static func cachedScene(candidateNames: [String]) -> SCNScene? {
        for candidate in candidateNames {
            let fileName = URL(fileURLWithPath: candidate).lastPathComponent
            guard let url = try? assetCacheFileURL(forAssetName: fileName)
            else {
                continue
            }

            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            let cacheKey = url.path as NSString
            if let cachedScene = RemoteAssetMemoryCache.sceneCache.object(
                forKey: cacheKey
            ) {
                return cachedScene
            }

            if let scene = try? SCNScene(url: url, options: nil) {
                RemoteAssetMemoryCache.sceneCache.setObject(
                    scene,
                    forKey: cacheKey
                )
                logger.debug("Loaded remote cached scene \(fileName)")
                return scene
            }
        }

        logger.error(
            "No remote cached scene found. Candidates: \(candidateNames.joined(separator: ", "))"
        )
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
            guard let url = try? assetCacheFileURL(forAssetName: candidate)
            else {
                continue
            }

            if FileManager.default.fileExists(atPath: url.path) {
                logger.debug("Resolved cached asset URL for \(candidate)")
                return url
            }
        }

        logger.error(
            "No cached asset URL found for \(assetName). Candidates: \(candidateNames.joined(separator: ", "))"
        )
        return nil
    }

    private func fetchManifest() async throws -> RemoteContentManifest {
        if let cachedManifest {
            Self.logger.info(
                "Using cached manifest. Resources: \(cachedManifest.resources.count), Assets: \(cachedManifest.assets?.count ?? 0)"
            )
            return cachedManifest
        }

        guard
            let configuration = loadConfiguration(),
            configuration.enabled,
            let manifestURL = URL(string: configuration.manifestURL)
        else {
            Self.logger.warning(
                "Remote refresh skipped. Config missing, disabled, or manifest URL invalid."
            )
            throw URLError(.badURL)
        }

        Self.logger.info(
            "Starting remote refresh from \(manifestURL.absoluteString)"
        )

        let (manifestData, manifestResponse) = try await URLSession.shared.data(
            from: manifestURL
        )
        try Self.validateHTTPResponse(manifestResponse, url: manifestURL)
        Self.logger.info("Manifest downloaded successfully.")

        let manifest = try JSONDecoder().decode(
            RemoteContentManifest.self,
            from: manifestData
        )
        cachedManifest = manifest
        Self.logger.info(
            "Manifest decoded. Resources: \(manifest.resources.count), Assets: \(manifest.assets?.count ?? 0)"
        )
        return manifest
    }

    private func buildStartupPlan(
        manifest: RemoteContentManifest,
        versions: [String: String]
    ) -> RemoteContentStartupPlan {
        let pendingResourceCount = manifest.resources.reduce(into: 0) {
            count,
            resource in
            if !isResourceCurrent(resource, versions: versions) {
                count += 1
            }
        }
        let pendingAssetCount = (manifest.assets ?? []).reduce(into: 0) {
            count,
            asset in
            if !isAssetCurrent(asset, versions: versions) {
                count += 1
            }
        }

        let estimatedDownloadBytes =
            manifest.resources.reduce(into: Int64(0)) { total, resource in
                if !isResourceCurrent(resource, versions: versions) {
                    total += Self.estimatedSize(
                        for: resource.url,
                        fallbackName: resource.name
                    )
                }
            }
            + (manifest.assets ?? []).reduce(into: Int64(0)) { total, asset in
                if !isAssetCurrent(asset, versions: versions) {
                    total += Self.estimatedSize(
                        for: asset.url,
                        fallbackName: asset.name
                    )
                }
            }

        return RemoteContentStartupPlan(
            pendingResourceCount: pendingResourceCount,
            pendingAssetCount: pendingAssetCount,
            estimatedDownloadBytes: estimatedDownloadBytes
        )
    }

    private nonisolated static func installedContentVersion() -> Int? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: installedContentVersionKey) != nil else {
            return nil
        }
        return defaults.integer(forKey: installedContentVersionKey)
    }

    private nonisolated static func saveInstalledContentVersion(
        _ version: Int?
    ) {
        guard let version else { return }
        UserDefaults.standard.set(version, forKey: installedContentVersionKey)
    }

    private nonisolated static func requiresMandatoryUpdate(
        manifestVersion: Int?,
        installedVersion: Int?
    ) -> Bool {
        guard let manifestVersion else { return false }
        guard let installedVersion else { return true }
        return manifestVersion > installedVersion
    }

    private func processResource(
        _ resource: RemoteContentResource,
        versions: inout [String: String]
    ) async -> (didChangeContent: Bool, failedName: String?) {
        guard let resourceURL = URL(string: resource.url) else {
            Self.logger.error(
                "Invalid resource URL for \(resource.name): \(resource.url)"
            )
            return (false, "\(resource.name).json")
        }

        do {
            let cacheURL = try Self.cacheFileURL(forResource: resource.name)
            let hasMatchingVersion =
                versions[resource.name] == resource.version
                && fileManager.fileExists(atPath: cacheURL.path)

            if hasMatchingVersion {
                Self.logger.debug(
                    "Resource cache hit: \(resource.name).json version \(resource.version)"
                )
                return (false, nil)
            }

            Self.logger.info(
                "Downloading resource \(resource.name).json from \(resourceURL.absoluteString)"
            )

            let (resourceData, resourceResponse) = try await URLSession.shared
                .data(from: resourceURL)
            try Self.validateHTTPResponse(resourceResponse, url: resourceURL)

            try await Self.writeData(resourceData, to: cacheURL)
            Self.logger.info(
                "Saved resource \(resource.name).json to cache: \(cacheURL.lastPathComponent)"
            )
            versions[resource.name] = resource.version
            return (true, nil)
        } catch {
            Self.logger.error(
                "Failed resource \(resource.name).json: \(error.localizedDescription)"
            )
            return (false, "\(resource.name).json")
        }
    }

    private func processAsset(
        _ asset: RemoteContentAsset,
        versions: inout [String: String],
        updatePublishedProgress: Bool
    ) async -> (didChangeContent: Bool, failedName: String?) {
        do {
            let didChangeContent = try await downloadAsset(
                asset,
                versions: &versions,
                updatePublishedProgress: updatePublishedProgress
            )
            return (didChangeContent, nil)
        } catch {
            Self.logger.error(
                "Failed asset \(asset.name): \(error.localizedDescription)"
            )
            return (false, asset.name)
        }
    }

    private func downloadAsset(
        _ asset: RemoteContentAsset,
        versions: inout [String: String],
        updatePublishedProgress: Bool
    ) async throws -> Bool {
        guard let assetURL = URL(string: asset.url) else {
            Self.logger.error(
                "Invalid asset URL for \(asset.name): \(asset.url)"
            )
            throw URLError(.badURL)
        }

        let cacheURL = try Self.assetCacheFileURL(forAssetName: asset.name)
        let versionKey = "asset:\(asset.name)"
        let hasMatchingVersion =
            versions[versionKey] == (asset.version ?? "static")
            && fileManager.fileExists(atPath: cacheURL.path)

        if hasMatchingVersion {
            Self.logger.debug(
                "Asset cache hit: \(asset.name) version \(asset.version ?? "static")"
            )
            return false
        }

        if updatePublishedProgress {
            setBackgroundStatusText("Downloading \(asset.name)")
        }

        Self.logger.info(
            "Downloading asset \(asset.name) from \(assetURL.absoluteString)"
        )

        let assetData = try await downloadAssetData(
            for: asset,
            primaryURL: assetURL
        )

        try await Self.writeData(assetData, to: cacheURL)
        Self.removeCachedAsset(named: asset.name)
        Self.logger.info(
            "Saved asset \(asset.name) to cache: \(cacheURL.lastPathComponent)"
        )
        versions[versionKey] = asset.version ?? "static"
        return true
    }

    private func downloadAssetData(
        for asset: RemoteContentAsset,
        primaryURL: URL
    ) async throws -> Data {
        do {
            let (assetData, assetResponse) = try await URLSession.shared.data(
                from: primaryURL
            )
            try Self.validateHTTPResponse(assetResponse, url: primaryURL)
            return assetData
        } catch let error as RemoteContentError {
            guard case .invalidHTTPStatusCode(let statusCode, _) = error,
                statusCode == 404
            else {
                throw error
            }

            for fallbackURL in Self.imageFallbackURLs(
                for: asset,
                primaryURL: primaryURL
            ) {
                do {
                    Self.logger.info(
                        "Retrying asset \(asset.name) with fallback URL \(fallbackURL.absoluteString)"
                    )
                    let (assetData, assetResponse) = try await URLSession.shared
                        .data(
                            from: fallbackURL
                        )
                    try Self.validateHTTPResponse(
                        assetResponse,
                        url: fallbackURL
                    )
                    return assetData
                } catch {
                    continue
                }
            }

            throw error
        }
    }

    private func runBackgroundPreload() async {
        isBackgroundPreloading = true
        setBackgroundPreloadProgress(0, force: true)
        setBackgroundStatusText("Preparing background preload")
        defer {
            isBackgroundPreloading = false
            setBackgroundPreloadProgress(1, force: true)
        }

        do {
            try Self.ensureCacheDirectory()
            let manifest = try await fetchManifest()
            var versions = await Self.loadCachedVersions()
            let assets = manifest.assets ?? []
            let missingAssets = assets.filter {
                !isAssetCurrent($0, versions: versions)
            }

            guard !missingAssets.isEmpty else {
                setBackgroundStatusText("All assets already cached")
                return
            }

            for (index, asset) in missingAssets.enumerated() {
                if Task.isCancelled {
                    return
                }

                _ = await processAsset(
                    asset,
                    versions: &versions,
                    updatePublishedProgress: true
                )

                setBackgroundPreloadProgress(
                    Self.progressValue(
                        completed: index + 1,
                        total: missingAssets.count
                    )
                )
            }

            try await Self.saveCachedVersions(versions)
            JSONResourceLoader.invalidateCache()
            startupPlan = buildStartupPlan(
                manifest: manifest,
                versions: versions
            )
            setBackgroundStatusText("Background preload complete")
        } catch {
            setBackgroundStatusText("Background preload failed")
            Self.logger.error(
                "Background preload failed: \(error.localizedDescription)"
            )
        }
    }

    private func runOnDemandAssetDownload(
        requestedName: String,
        candidateNames: [String]
    ) async {
        do {
            try Self.ensureCacheDirectory()
            let manifest = try await fetchManifest()
            var versions = await Self.loadCachedVersions()

            for candidate in candidateNames {
                guard let asset = asset(named: candidate, in: manifest) else {
                    continue
                }

                _ = await processAsset(
                    asset,
                    versions: &versions,
                    updatePublishedProgress: false
                )
                try await Self.saveCachedVersions(versions)
                startupPlan = buildStartupPlan(
                    manifest: manifest,
                    versions: versions
                )
                return
            }

            Self.logger.debug("No on-demand asset found for \(requestedName)")
        } catch {
            Self.logger.error(
                "On-demand asset download failed for \(requestedName): \(error.localizedDescription)"
            )
        }
    }

    private func asset(
        named assetName: String,
        in manifest: RemoteContentManifest
    ) -> RemoteContentAsset? {
        let normalizedAssetName = URL(fileURLWithPath: assetName)
            .lastPathComponent
        return (manifest.assets ?? []).first {
            URL(fileURLWithPath: $0.name).lastPathComponent
                == normalizedAssetName
        }
    }

    private func setStatusText(_ newValue: String) {
        guard statusText != newValue else { return }
        statusText = newValue
    }

    private func setBackgroundStatusText(_ newValue: String) {
        guard backgroundStatusText != newValue else { return }
        backgroundStatusText = newValue
    }

    private func setRefreshProgress(_ newValue: Double, force: Bool = false) {
        let clampedValue = min(1, max(0, newValue))
        guard
            force
                || abs(refreshProgress - clampedValue)
                    >= progressUpdateThreshold
                || clampedValue == 0
                || clampedValue == 1
        else { return }
        refreshProgress = clampedValue
    }

    private func setBackgroundPreloadProgress(
        _ newValue: Double,
        force: Bool = false
    ) {
        let clampedValue = min(1, max(0, newValue))
        guard
            force
                || abs(backgroundPreloadProgress - clampedValue)
                    >= progressUpdateThreshold
                || clampedValue == 0
                || clampedValue == 1
        else { return }
        backgroundPreloadProgress = clampedValue
    }

    private func assetsForStartup(
        from manifest: RemoteContentManifest,
        mode: RemoteContentRefreshMode
    ) -> [RemoteContentAsset] {
        let allAssets = manifest.assets ?? []

        switch mode {
        case .fullPreload:
            return allAssets
        case .bootstrap:
            let immediateAssets = allAssets.filter(
                Self.shouldLoadDuringBootstrap
            )
            let modelAssets = bootstrapCharacterModelAssets(from: manifest)
            var seenAssetNames = Set<String>()

            return (immediateAssets + modelAssets).filter { asset in
                seenAssetNames.insert(asset.name).inserted
            }
        }
    }

    private func bootstrapCharacterModelAssets(
        from manifest: RemoteContentManifest
    ) -> [RemoteContentAsset] {
        var requiredModelNames = Set<String>()

        func appendCharacter(_ character: CharacterStats) {
            let modelName = character.model.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if !modelName.isEmpty {
                requiredModelNames.insert(modelName)
            }

            if let battleModel = character.battleModel?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !battleModel.isEmpty
            {
                requiredModelNames.insert(battleModel)
            }
        }

        loadGamePlayers().forEach(appendCharacter)
        appendCharacter(loadBattlePlayer())
        loadSummonCharacters().forEach { appendCharacter($0.stats()) }
        loadMaps().forEach { appendCharacter($0.enemy) }
        loadTutorialDefinitions().forEach { tutorial in
            appendCharacter(tutorial.player)
            tutorial.allEnemies.forEach(appendCharacter)
        }
        loadGlobeEventChapters().forEach { chapter in
            for point in chapter.points {
                for battle in point.battles {
                    battle.battleEnemies.forEach(appendCharacter)
                }
            }
        }

        for definition in loadCharacterClassDefinitions() {
            for variant in definition.variants {
                appendCharacter(
                    variant.makeCharacter(named: definition.defaultName)
                )
            }
        }

        var resolvedAssets = [RemoteContentAsset]()
        var seenAssetNames = Set<String>()

        for modelName in requiredModelNames {
            let candidateNames = Self.assetCandidates(
                for: modelName,
                preferredExtensions: ["usdz", "scn"]
            )

            for candidateName in candidateNames {
                guard let asset = asset(named: candidateName, in: manifest)
                else {
                    continue
                }

                if seenAssetNames.insert(asset.name).inserted {
                    resolvedAssets.append(asset)
                }
                break
            }
        }

        return resolvedAssets
    }

    private func isResourceCurrent(
        _ resource: RemoteContentResource,
        versions: [String: String]
    ) -> Bool {
        guard let cacheURL = try? Self.cacheFileURL(forResource: resource.name)
        else {
            return false
        }

        return versions[resource.name] == resource.version
            && fileManager.fileExists(atPath: cacheURL.path)
    }

    private func isAssetCurrent(
        _ asset: RemoteContentAsset,
        versions: [String: String]
    ) -> Bool {
        guard
            let cacheURL = try? Self.assetCacheFileURL(forAssetName: asset.name)
        else {
            return false
        }

        let versionKey = "asset:\(asset.name)"
        return versions[versionKey] == (asset.version ?? "static")
            && fileManager.fileExists(atPath: cacheURL.path)
    }

    private func hasCachedAsset(named assetName: String) -> Bool {
        guard let url = try? Self.assetCacheFileURL(forAssetName: assetName)
        else {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }

    private func loadConfiguration() -> RemoteContentConfiguration? {
        guard
            let url = Bundle.main.url(
                forResource: "remote_content_config",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url)
        else {
            Self.logger.error("remote_content_config.json missing from bundle.")
            return nil
        }

        guard
            let configuration = try? JSONDecoder().decode(
                RemoteContentConfiguration.self,
                from: data
            )
        else {
            Self.logger.error("Failed to decode remote_content_config.json")
            return nil
        }

        Self.logger.info(
            "Loaded remote config. Enabled: \(configuration.enabled), manifest: \(configuration.manifestURL)"
        )
        return configuration
    }

    private nonisolated static func validateHTTPResponse(
        _ response: URLResponse,
        url: URL
    ) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RemoteContentError.invalidHTTPStatusCode(
                httpResponse.statusCode,
                url.absoluteString
            )
        }
    }

    private nonisolated static func writeData(_ data: Data, to url: URL)
        async throws
    {
        try await Task.detached(priority: .utility) {
            try data.write(to: url, options: .atomic)
        }.value
    }

    private nonisolated static func removeCachedAsset(named assetName: String) {
        for candidate in assetCandidates(
            for: assetName,
            preferredExtensions: ["png", "jpg", "jpeg", "webp", "usdz", "scn"]
        ) {
            RemoteAssetMemoryCache.imageCache.removeObject(
                forKey: candidate as NSString
            )
            guard let url = try? assetCacheFileURL(forAssetName: candidate)
            else {
                continue
            }
            RemoteAssetMemoryCache.sceneCache.removeObject(
                forKey: url.path as NSString
            )
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

    private nonisolated static func cacheFileURL(forResource resource: String)
        throws
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

    private nonisolated static func assetCacheFileURL(
        forAssetName assetName: String
    ) throws
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

    private nonisolated static func imageCandidates(for imageName: String)
        -> [String]
    {
        assetCandidates(
            for: imageName,
            preferredExtensions: ["png", "jpg", "jpeg", "webp"]
        )
    }

    private nonisolated static func assetCandidates(
        for assetName: String,
        preferredExtensions: [String]
    ) -> [String] {
        let trimmedName = assetName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        var candidates = [String]()

        func appendCandidate(_ candidate: String) {
            let normalizedCandidate = candidate.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard
                !normalizedCandidate.isEmpty,
                !candidates.contains(normalizedCandidate)
            else {
                return
            }
            candidates.append(normalizedCandidate)
        }

        appendCandidate(trimmedName)

        for alias in assetAliases(for: trimmedName) {
            appendCandidate(alias)
        }

        if !trimmedName.contains(".") {
            for baseName in candidates {
                for preferredExtension in preferredExtensions {
                    appendCandidate("\(baseName).\(preferredExtension)")
                }
            }
        }

        return candidates
    }

    private nonisolated static func assetAliases(for assetName: String)
        -> [String]
    {
        return []
    }

    private nonisolated static func shouldLoadDuringBootstrap(
        _ asset: RemoteContentAsset
    ) -> Bool {
        let fileName = URL(fileURLWithPath: asset.name).lastPathComponent
            .lowercased()
        let path =
            URL(string: asset.url)?.path.lowercased() ?? asset.url.lowercased()

        if fileName.hasSuffix(".png")
            || fileName.hasSuffix(".jpg")
            || fileName.hasSuffix(".jpeg")
            || fileName.hasSuffix(".webp")
            || fileName.hasSuffix(".mp3")
        {
            return true
        }

        if path.hasSuffix(".png")
            || path.hasSuffix(".jpg")
            || path.hasSuffix(".jpeg")
            || path.hasSuffix(".webp")
            || path.hasSuffix(".mp3")
        {
            return true
        }

        return false
    }

    private nonisolated static func imageFallbackURLs(
        for asset: RemoteContentAsset,
        primaryURL: URL
    ) -> [URL] {
        let pathExtension = primaryURL.pathExtension.lowercased()
        guard ["png", "jpg", "jpeg", "webp"].contains(pathExtension) else {
            return []
        }

        let fallbackExtensions: [String]
        if asset.name.hasPrefix("texture_") {
            fallbackExtensions = ["jpg", "jpeg", "png", "webp"]
        } else {
            fallbackExtensions = ["png", "jpg", "jpeg", "webp"]
        }

        let assetFileName = URL(fileURLWithPath: asset.name).lastPathComponent
        let assetBaseName = URL(fileURLWithPath: assetFileName)
            .deletingPathExtension()
            .lastPathComponent
        let urlBaseName = primaryURL.deletingPathExtension().lastPathComponent
        let baseName = assetBaseName.isEmpty ? urlBaseName : assetBaseName

        return fallbackExtensions.compactMap { fallbackExtension in
            guard fallbackExtension != pathExtension else { return nil }

            var fallbackURL = primaryURL.deletingPathExtension()
            fallbackURL.appendPathExtension(fallbackExtension)

            guard
                fallbackURL.lastPathComponent
                    == "\(baseName).\(fallbackExtension)"
            else {
                fallbackURL.deleteLastPathComponent()
                fallbackURL.appendPathComponent(
                    "\(baseName).\(fallbackExtension)"
                )
                return fallbackURL
            }

            return fallbackURL
        }
    }

    private nonisolated static func estimatedSize(
        for urlString: String,
        fallbackName: String
    ) -> Int64 {
        let lowercasedName =
            (URL(string: urlString)?.pathExtension.isEmpty == false
            ? urlString
            : fallbackName).lowercased()

        if lowercasedName.hasSuffix(".json") {
            return 25_000
        }
        if lowercasedName.hasSuffix(".png")
            || lowercasedName.hasSuffix(".jpg")
            || lowercasedName.hasSuffix(".jpeg")
            || lowercasedName.hasSuffix(".webp")
        {
            return 1_500_000
        }
        if lowercasedName.hasSuffix(".usdz") {
            return 8_000_000
        }
        if lowercasedName.hasSuffix(".mp4") {
            return 30_000_000
        }
        if lowercasedName.hasSuffix(".mp3") {
            return 6_000_000
        }

        return 1_000_000
    }

    private nonisolated static func progressValue(
        completed: Int,
        total: Int
    ) -> Double {
        guard total > 0 else { return 1 }
        return min(1, max(0, Double(completed) / Double(total)))
    }

    private nonisolated static func loadCachedVersions() async -> [String:
        String]
    {
        await Task.detached(priority: .utility) {
            guard
                let versionsURL = try? versionsFileURL(),
                let data = try? Data(contentsOf: versionsURL),
                let decoded = try? JSONDecoder().decode(
                    [String: String].self,
                    from: data
                )
            else {
                return [:]
            }

            return decoded
        }.value
    }

    private nonisolated static func saveCachedVersions(
        _ versions: [String: String]
    ) async throws {
        let data = try JSONEncoder().encode(versions)
        try await Task.detached(priority: .utility) {
            try data.write(to: versionsFileURL(), options: .atomic)
        }.value
    }
}
