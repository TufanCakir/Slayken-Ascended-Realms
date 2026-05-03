//
//  StartView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

private struct StartBackgroundAsset {
    let name: String
    let image: UIImage
}

struct StartView: View {
    private let backgroundRotationInterval = 2.0
    private let backgroundFadeDuration = 0.70

    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onStart: () -> Void

    @State private var currentBackgroundIndex = 0
    @State private var backgroundRotationTask: Task<Void, Never>?
    @State private var resolvedPreviewBackgroundImages = [String]()
    @State private var preloadedBackgroundAssets = [StartBackgroundAsset]()
    @State private var displayedBackgroundImage: StartBackgroundAsset?
    @State private var fadingBackgroundImage: StartBackgroundAsset?
    @State private var displayedBackgroundOpacity = 1.0
    @State private var fadingBackgroundOpacity = 0.0

    private var classDefinitions: [CharacterClassDefinition] {
        loadCharacterClassDefinitions()
    }

    private var appVersionText: String {
        let version =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
        return version?.isEmpty == false ? version ?? "1.0" : "1.0."
    }

    private var copyrightYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    private var previewBackgroundImages: [String] {
        let summonPreviews = gameState.summonCharacters.map(\.summonImage)
        let classPreviews = classDefinitions.flatMap { definition in
            definition.variants.map(\.image)
        }

        var seen = Set<String>()
        return (summonPreviews + classPreviews).filter {
            seen.insert($0).inserted
        }
    }

    private var currentBackgroundAsset: StartBackgroundAsset? {
        guard !preloadedBackgroundAssets.isEmpty else { return nil }
        let safeIndex = min(
            currentBackgroundIndex,
            preloadedBackgroundAssets.count - 1
        )
        return preloadedBackgroundAssets[safeIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                versionLabel
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                Spacer()

                centerContent
                    .padding(.horizontal, 24)

                Spacer()

                copyrightLabel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                onStart()
            }
            .background(backgroundView.ignoresSafeArea())
            .onAppear {
                syncDisplayedBackgroundImage()
                startBackgroundRotation()
            }
            .task(id: previewBackgroundImages) {
                let imageNames = previewBackgroundImages
                var resolvedAssets = [StartBackgroundAsset]()

                for imageName in imageNames {
                    guard
                        RemoteContentManager.hasCachedOrBundledImage(
                            named: imageName
                        )
                    else { continue }
                    guard
                        let image =
                            await RemoteContentManager
                            .loadCachedOrBundledImage(named: imageName)
                    else { continue }
                    resolvedAssets.append(
                        StartBackgroundAsset(name: imageName, image: image)
                    )
                }
                resolvedPreviewBackgroundImages = resolvedAssets.map(\.name)
                preloadedBackgroundAssets = resolvedAssets
                currentBackgroundIndex = min(
                    currentBackgroundIndex,
                    max(resolvedAssets.count - 1, 0)
                )
                syncDisplayedBackgroundImage()
                startBackgroundRotation()
            }
            .onChange(of: currentBackgroundIndex) { _, _ in
                syncDisplayedBackgroundImage()
            }
            .onDisappear {
                backgroundRotationTask?.cancel()
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            if let fadingBackgroundImage {
                Image(uiImage: fadingBackgroundImage.image)
                    .resizable()
                    .scaledToFill()
                    .opacity(fadingBackgroundOpacity)
            }

            if let displayedBackgroundImage {
                Image(uiImage: displayedBackgroundImage.image)
                    .resizable()
                    .scaledToFill()
                    .opacity(displayedBackgroundOpacity)
                    .id(displayedBackgroundImage.name)
            } else {
                Color.black
            }
        }
    }

    private var versionLabel: some View {
        Text(appVersionText)
            .font(.system(size: 10, weight: .semibold, design: .serif))
            .foregroundStyle(.white.opacity(0.62))
            .shadow(color: .black.opacity(0.55), radius: 6, y: 2)
    }

    private var centerContent: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text("SLAYKEN")
                Text("ASCENDED")
                Text("REALMS")
            }
            .font(.system(size: 40, weight: .black, design: .serif))
            .tracking(4)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black, radius: 18, y: 8)

            startPrompt
        }
    }

    private var startPrompt: some View {
        VStack(spacing: 10) {
            Text("Zum Starten\nantippen")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 18, y: 8)
                .fixedSize(horizontal: true, vertical: true)

            HStack(spacing: 8) {
                decorativeLine
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.blue)
                decorativeLine
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var decorativeLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.24))
            .frame(width: 54, height: 1)
    }

    private var copyrightLabel: some View {
        VStack(spacing: 4) {
            Text("© \(copyrightYear) Tufan Cakir. Alle Rechte vorbehalten.")
                .font(.system(size: 10, weight: .semibold, design: .serif))

            Text(
                "SLAYKEN ASCENDED REALMS und alle zugehörigen Namen sind Eigentum von Tufan Cakir."
            )
            .font(.system(size: 7, weight: .regular, design: .serif))
        }
        .foregroundStyle(.white.opacity(0.54))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .shadow(color: .black.opacity(0.52), radius: 6, y: 2)
    }

    private func startBackgroundRotation() {
        backgroundRotationTask?.cancel()
        guard preloadedBackgroundAssets.count > 1 else { return }
        backgroundRotationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(backgroundRotationInterval))
                if Task.isCancelled { break }
                await MainActor.run {
                    currentBackgroundIndex =
                        (currentBackgroundIndex + 1)
                        % preloadedBackgroundAssets.count
                }
            }
        }
    }

    private func syncDisplayedBackgroundImage() {
        guard let currentBackgroundAsset else {
            displayedBackgroundImage = nil
            fadingBackgroundImage = nil
            displayedBackgroundOpacity = 1
            fadingBackgroundOpacity = 0
            return
        }

        guard displayedBackgroundImage?.name != currentBackgroundAsset.name
        else {
            displayedBackgroundOpacity = 1
            fadingBackgroundOpacity = 0
            return
        }

        let previousBackgroundImage = displayedBackgroundImage
        let fadeDuration = backgroundFadeDuration

        fadingBackgroundImage = previousBackgroundImage
        fadingBackgroundOpacity = previousBackgroundImage == nil ? 0 : 1
        displayedBackgroundImage = currentBackgroundAsset
        displayedBackgroundOpacity = 0

        Task { @MainActor in
            await Task.yield()
            withAnimation(.easeInOut(duration: fadeDuration)) {
                displayedBackgroundOpacity = 1
                fadingBackgroundOpacity = 0
            }
            try? await Task.sleep(for: .seconds(fadeDuration + 0.05))
            if fadingBackgroundImage?.name == previousBackgroundImage?.name {
                fadingBackgroundImage = nil
            }
        }
    }
}

#Preview {
    StartView(onStart: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
