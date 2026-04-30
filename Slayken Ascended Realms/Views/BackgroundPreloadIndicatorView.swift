//
//  BackgroundPreloadIndicatorView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct BackgroundPreloadIndicatorView: View {
    let progress: Double
    let statusText: String

    private var clampedProgress: Double {
        min(1, max(0, progress))
    }

    private var percentageText: String {
        "\(Int(clampedProgress * 100))%"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(
                        Color(red: 0.18, green: 0.72, blue: 1.0)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Background Preload")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)

                    Text(statusText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Text(percentageText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.72, blue: 1.0),
                                    Color(red: 0.14, green: 0.42, blue: 1.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width
                                * max(0.06, clampedProgress)
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.72))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        .padding(.horizontal, 18)
        .padding(.top, 10)
    }
}
