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
    let requiresMandatoryUpdate: Bool
    let failureMessage: String?
    let requiresRetry: Bool
    let maintenance: RemoteContentMaintenance?
    let isConnected: Bool
    @Binding var showOptions: Bool
    let onPreloadAll: () -> Void
    let onPlayWithoutPreload: () -> Void
    let onRetry: () -> Void

    @State private var spin = false

    private var estimatedSizeText: String {
        guard let plan else { return "wird berechnet" }
        return plan.formattedEstimatedSize
    }

    private var isMaintenanceMode: Bool {
        maintenance?.enabled == true
    }

    private var maintenanceTitle: String {
        maintenance?.title ?? "Wartungsarbeiten"
    }

    private var maintenanceMessage: String {
        maintenance?.message
            ?? "Slayken Ascended Realms ist gerade kurz nicht erreichbar. Bitte versuche es spaeter erneut."
    }

    private var summaryText: String {
        if isMaintenanceMode {
            return maintenanceMessage
        }

        if let failureMessage, !failureMessage.isEmpty {
            return failureMessage
        }

        guard let plan else {
            return "Manifest und Cache werden geprueft."
        }

        if plan.totalPendingCount == 0 {
            return "Alles ist bereit."
        }

        return "Ca. \(estimatedSizeText) für \(plan.totalPendingCount) Inhalte."
    }

    private var pendingResourceCountText: String {
        "\(plan?.pendingResourceCount ?? 0)"
    }

    private var pendingAssetCountText: String {
        "\(plan?.pendingAssetCount ?? 0)"
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 16) {

                titleBlock

                centerCard

            }

            if shouldShowOverlay {
                optionOverlay
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isMaintenanceMode, !requiresMandatoryUpdate,
                !isPreparingPlan, !isStarting
            else {
                return
            }
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
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    Color(red: 0.01, green: 0.02, blue: 0.05),
                    Color.black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 12,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .offset(x: -120, y: -210)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.14), .clear],
                        center: .center,
                        startRadius: 16,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .offset(x: 140, y: 220)
        }
        .ignoresSafeArea()
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text("Realm Sync")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(
                isMaintenanceMode
                    ? "Die Realm-Server sind kurz offline."
                    : requiresRetry
                        ? "Download erneut starten."
                        : requiresMandatoryUpdate
                            ? "Update zuerst laden."
                            : "Jetzt laden oder direkt starten."
            )
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
        }
    }

    private var centerCard: some View {
        VStack(spacing: 16) {
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
                                colors: [.blue, .white, .blue],
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
                    isMaintenanceMode
                        ? maintenanceTitle
                        : requiresRetry
                            ? "Laden fehlgeschlagen"
                            : isStarting
                                ? "Lade Inhalte"
                                : requiresMandatoryUpdate
                                    ? "Update nötig"
                                    : "Download wählen"
                )
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

                Text(
                    isPreparingPlan
                        ? "Plan wird vorbereitet." : summaryText
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                if isMaintenanceMode, let retryAfter = maintenance?.retryAfter,
                    !retryAfter.isEmpty
                {
                    Text(retryAfter)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.yellow.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
            }

            if isMaintenanceMode {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(.yellow)
                    .padding(.top, 4)
            } else if requiresMandatoryUpdate {
                updateInfoBlock
            }

            if isMaintenanceMode {
                EmptyView()
            } else if requiresRetry {
                retryBlock
            } else if isStarting || isPreparingPlan {
                Text(isPreparingPlan ? "Plan wird vorbereitet" : statusText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)

                progressBlock
            }

        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.10, blue: 0.22).opacity(0.94),
                    Color(red: 0.02, green: 0.06, blue: 0.16).opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.24),
                            Color.cyan.opacity(0.16),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.blue.opacity(0.16), radius: 18, y: 8)
        .shadow(color: .black.opacity(0.38), radius: 26, y: 14)
    }

    private var updateInfoBlock: some View {
        HStack(spacing: 10) {
            infoPill(title: "Größe", value: estimatedSizeText)
            infoPill(title: "Daten", value: pendingResourceCountText)
            infoPill(title: "Assets", value: pendingAssetCountText)
        }
    }

    private var progressBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                progressStatPill(
                    title: "Geladen",
                    value: progressText
                )

                progressStatPill(
                    title: "Fehlt",
                    value: remainingProgressText
                )
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.10))

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
                                18,
                                geometry.size.width * min(max(progress, 0), 1)
                            )
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("Fortschritt")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.66))

                Spacer()

                Text("\(progressText) geladen")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.84))
            }

            Text("\(remainingProgressText) fehlen noch")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }

    private var optionOverlay: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Download wählen")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(
                    requiresMandatoryUpdate
                        ? "Ca. \(estimatedSizeText). Erst laden, dann spielen."
                        : "Ca. \(estimatedSizeText). Oder direkt starten."
                )
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)

                updateInfoBlock

                VStack(spacing: 16) {
                    optionButton(
                        title: requiresMandatoryUpdate
                            ? "Update herunterladen" : "Alles Laden",
                        subtitle: requiresMandatoryUpdate
                            ? "Lädt alles jetzt."
                            : "Lädt alles sofort.",
                        fill: Color(red: 0.12, green: 0.42, blue: 1.0),
                        action: {
                            showOptions = false
                            onPreloadAll()
                        }
                    )

                    if !requiresMandatoryUpdate {
                        optionButton(
                            title: "Preload Laden",
                            subtitle: "Rest später laden.",
                            fill: Color(red: 0.08, green: 0.56, blue: 0.38),
                            action: {
                                showOptions = false
                                onPlayWithoutPreload()
                            }
                        )
                    }

                    if !requiresMandatoryUpdate {
                        optionButton(
                            title: "Abbrechen",
                            subtitle: "Fenster schliessen.",
                            fill: Color.white.opacity(0.12),
                            action: {
                                showOptions = false
                            }
                        )
                    }
                }
            }
            .padding()
            .background(
                Color.black.opacity(0.34),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.blue.opacity(0.16), radius: 18, y: 8)
            .shadow(color: .black.opacity(0.38), radius: 28, y: 14)
            .padding(.horizontal, 22)
        }
    }

    private var retryBlock: some View {
        VStack(spacing: 14) {
            Text(
                isConnected
                    ? "Verbindung wieder da. Starte den kompletten Download erneut."
                    : "Bitte Internetverbindung wiederherstellen. Danach den kompletten Download erneut starten."
            )
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white.opacity(0.78))
            .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text(isConnected ? "Erneut laden" : "Warte auf Internet")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        isConnected
                            ? Color(red: 0.12, green: 0.42, blue: 1.0)
                            : Color.white.opacity(0.10)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isConnected)
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.62))

            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func progressStatPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))

            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .padding()
            .background(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: fill.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var progressText: String {
        "\(Int(min(max(progress, 0), 1) * 100))%"
    }

    private var remainingProgressText: String {
        "\(100 - Int(min(max(progress, 0), 1) * 100))%"
    }

    private var shouldShowOverlay: Bool {
        !isMaintenanceMode && !requiresRetry && !isStarting
            && (requiresMandatoryUpdate || showOptions)
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
