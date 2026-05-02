//
//  RemoteAssetImage.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct RemoteAssetImage<Placeholder: View>: View {
    let imageName: String
    let contentMode: ContentMode
    let placeholder: () -> Placeholder
    @EnvironmentObject private var remoteContent: RemoteContentManager
    @State private var resolvedImage: UIImage?

    init(
        _ imageName: String,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.imageName = imageName
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = resolvedImage
                ?? RemoteContentManager.memoryCachedImage(named: imageName)
            {
                configuredImage(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: imageName) {
            resolvedImage = RemoteContentManager.memoryCachedImage(
                named: imageName
            )
            if resolvedImage == nil {
                resolvedImage =
                    await RemoteContentManager.loadCachedOrBundledImage(
                        named: imageName
                    )
            }
            await remoteContent.downloadAssetIfNeeded(named: imageName)
            if resolvedImage == nil {
                resolvedImage =
                    await RemoteContentManager.loadCachedOrBundledImage(
                        named: imageName
                    )
            }
        }
    }

    @ViewBuilder
    private func configuredImage(_ image: Image) -> some View {
        switch contentMode {
        case .fit:
            image
                .resizable()
                .scaledToFit()
        case .fill:
            image
                .resizable()
                .scaledToFill()
        @unknown default:
            image
                .resizable()
                .scaledToFill()
        }
    }
}
