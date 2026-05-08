//
//  LoadingOverlayView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let title: String
    let subtitle: String
    let progress: Double?
    let statusText: String?

    @State private var spin = false

    init(
        title: String = "Entering Ascended Realms",
        subtitle: String =
            "Deine Welt, Battle-Daten und Event-Pfade werden vorbereitet.",
        progress: Double? = nil,
        statusText: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.statusText = statusText
    }

    private var normalizedProgress: Double? {
        guard let progress else { return nil }
        return min(max(progress, 0), 1)
    }

    private var progressText: String {
        "\(Int((normalizedProgress ?? 0) * 100))%"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            centerPanel
                .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.05).repeatForever(autoreverses: false)
            ) {
                spin = true
            }
        }
    }

    private var centerPanel: some View {
        VStack(spacing: 18) {
            spinnerBlock

            Text(title)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let statusText, !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Color.white.opacity(0.08),
                        in: Capsule()
                    )
            }

            if let normalizedProgress {
                progressBlock(progress: normalizedProgress)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var spinnerBlock: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 8)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .blue,
                                .blue,
                                .white,
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(spin ? 360 : 0))
            }

            Text("LOADING")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white.opacity(0.92))
                .tracking(3)
        }
    }

    private func progressBlock(progress: Double) -> some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.78, blue: 1.0),
                                    Color(red: 0.12, green: 0.44, blue: 1.0),
                                    .white,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                16,
                                geometry.size.width * progress
                            )
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("Fortschritt")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.64))

                Spacer()

                Text(progressText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.86))
            }
        }
        .padding(.top, 2)
    }
}
