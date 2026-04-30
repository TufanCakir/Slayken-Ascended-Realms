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
    let placeholder: () -> Placeholder

    init(
        _ imageName: String,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.imageName = imageName
        self.placeholder = placeholder
    }

    var body: some View {
        if let remoteImage = RemoteContentManager.cachedImage(named: imageName) {
            Image(uiImage: remoteImage)
                .resizable()
                .scaledToFill()
        } else if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            placeholder()
        }
    }
}
