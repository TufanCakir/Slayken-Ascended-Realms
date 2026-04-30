//
//  RemoteLoadingView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct RemoteLoadingView: View {
    let plan: RemoteContentStartupPlan?
    let isPreparingPlan: Bool
    let isStarting: Bool
    let progress: Double
    let statusText: String
    @Binding var showOptions: Bool
    let onPreloadAll: () -> Void
    let onPlayWithoutPreload: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    @State private var spin = false

    private var estimatedSizeText: String {
        guard let plan else { return "wird berechnet" }
        return plan.formattedEstimatedSize
    }

    private var summaryText: String {
        guard let plan else {
            return "Manifest, Dateien und Cache werden geprueft."
        }

        if plan.totalPendingCount == 0 {
            return "Alle bekannten Inhalte sind bereits im Cache vorhanden."
        }

        return
            "Volles Preload laedt ca. \(estimatedSizeText) mit \(plan.pendingResourceCount) Datenpaketen und \(plan.pendingAssetCount) Assets."
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 28) {
                Spacer(minLength: 24)

                titleBlock

                centerCard
                    .padding(.horizontal, 24)

                footerHint
                    .padding(.horizontal, 24)

                Spacer()
            }

            if showOptions && !isStarting {
                optionOverlay
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isPreparingPlan, !isStarting else { return }
            showOptions = true
        }
        .onAppear {
            updateSpinnerState(isAnimating: isStarting)
        }
        .onChange(of: isStarting) { _, isStarting in
            updateSpinnerState(isAnimating: isStarting)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            if let selectedTheme = theme.selectedTheme {
                RemoteAssetImage(selectedTheme.background) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.08, blue: 0.16),
                            Color(red: 0.01, green: 0.02, blue: 0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.08, blue: 0.16),
                        Color(red: 0.01, green: 0.02, blue: 0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.72),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text("Remote Loading")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text(
                "Waehlst du Voll-Preload, laedt die App alles direkt. Ohne Voll-Preload kannst du sofort starten und Inhalte werden spaeter nachgeladen."
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
        }
    }

    private var centerCard: some View {
        VStack(spacing: 18) {
            if isStarting {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 86, height: 86)

                    Circle()
                        .trim(
                            from: 0,
                            to: max(0.14, progress == 0 ? 0.22 : progress)
                        )
                        .stroke(
                            AngularGradient(
                                colors: [.cyan, .blue, .white, .cyan],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(spin ? 360 : 0))

                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.white)
                }
            }

            VStack(spacing: 8) {
                Text(
                    isStarting
                        ? "Inhalte werden geladen"
                        : "Tippe fuer Preload-Optionen"
                )
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)

                Text(
                    isPreparingPlan
                        ? "Preload-Plan wird aufgebaut." : summaryText
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            if isStarting || isPreparingPlan {
                progressBlock
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 28)
        .background(Color.black.opacity(0.4))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var progressBlock: some View {
        VStack(spacing: 10) {
            HStack {
                Text(isPreparingPlan ? "Plan" : statusText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))

                Spacer()

                Text(progressText)
                    .font(.system(size: 13, weight: .black))
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
                                    Color(red: 0.12, green: 0.78, blue: 1.0),
                                    Color(red: 0.15, green: 0.42, blue: 1.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0.05, progress))
                }
            }
            .frame(height: 12)
        }
    }

    private var footerHint: some View {
        VStack(spacing: 8) {
            Text("Preload alles")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)

            Text(
                "Lädt die komplette Remote-Liste jetzt direkt. Ohne Preload kannst du sofort spielen und der Rest wird spaeter nachgeladen."
            )
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
        }
    }

    private var optionOverlay: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Preload waehlen")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(.white)

                Text(
                    "Volles Paket: ca. \(estimatedSizeText). Du kannst auch direkt starten, dann werden Inhalte beim Spielen und im Hintergrund geladen."
                )
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    optionButton(
                        title: "Preload alles",
                        subtitle: "Lädt direkt alle bekannten Remote-Inhalte.",
                        fill: Color(red: 0.12, green: 0.42, blue: 1.0),
                        action: {
                            showOptions = false
                            onPreloadAll()
                        }
                    )

                    optionButton(
                        title: "Direkt spielen",
                        subtitle:
                            "Laedt nur die Spielbasis und den Rest spaeter.",
                        fill: Color(red: 0.08, green: 0.56, blue: 0.38),
                        action: {
                            showOptions = false
                            onPlayWithoutPreload()
                        }
                    )

                    optionButton(
                        title: "Abbrechen",
                        subtitle:
                            "Schliesst dieses Fenster. Tippe erneut fuer Optionen.",
                        fill: Color.white.opacity(0.12),
                        action: {
                            showOptions = false
                        }
                    )
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .background(Color.black.opacity(0.82))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(.horizontal, 22)
        }
    }

    private func optionButton(
        title: String,
        subtitle: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var progressText: String {
        if isPreparingPlan {
            return "..."
        }
        return "\(Int(progress * 100))%"
    }

    private func updateSpinnerState(isAnimating: Bool) {
        guard isAnimating else {
            spin = false
            return
        }

        withAnimation(
            .linear(duration: 1.05).repeatForever(autoreverses: false)
        ) {
            spin = true
        }
    }
}
