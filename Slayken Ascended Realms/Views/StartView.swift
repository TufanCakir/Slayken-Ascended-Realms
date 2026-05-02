//
//  StartView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct StartView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onStart: () -> Void

    @State private var currentBackgroundIndex = 0
    @State private var backgroundRotationTask: Task<Void, Never>?
    @State private var resolvedPreviewBackgroundImages = [String]()

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

    private var currentBackgroundImage: String? {
        guard !resolvedPreviewBackgroundImages.isEmpty else { return nil }
        let safeIndex = min(
            currentBackgroundIndex,
            resolvedPreviewBackgroundImages.count - 1
        )
        return resolvedPreviewBackgroundImages[safeIndex]
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
                startBackgroundRotation()
            }
            .task(id: previewBackgroundImages) {
                let imageNames = previewBackgroundImages
                let resolvedNames = await Task.detached(priority: .utility) {
                    imageNames.filter {
                        RemoteContentManager.hasCachedOrBundledImage(named: $0)
                    }
                }.value
                resolvedPreviewBackgroundImages = resolvedNames
                currentBackgroundIndex = min(
                    currentBackgroundIndex,
                    max(resolvedNames.count - 1, 0)
                )
            }
            .onDisappear {
                backgroundRotationTask?.cancel()
            }
        }
    }

    private var backgroundView: some View {
        Group {
            if let currentBackgroundImage {
                RemoteAssetImage(currentBackgroundImage) {
                    Color.black
                }
                .transition(.opacity)
                .id(currentBackgroundImage)
            } else {
                Color.black
            }
        }
        .animation(.easeInOut(duration: 0.8), value: currentBackgroundImage)
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
        guard previewBackgroundImages.count > 1 else { return }
        backgroundRotationTask?.cancel()
        backgroundRotationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                if Task.isCancelled { break }
                await MainActor.run {
                    currentBackgroundIndex =
                        (currentBackgroundIndex + 1)
                        % previewBackgroundImages.count
                }
            }
        }
    }
}

#Preview {
    StartView(onStart: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
