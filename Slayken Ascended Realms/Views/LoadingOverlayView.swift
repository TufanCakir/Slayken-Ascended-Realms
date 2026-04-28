//
//  LoadingOverlayView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI
import UIKit

struct LoadingOverlayView: View {
    let progress: Double
    let background: String

    @EnvironmentObject var theme: ThemeManager
    @State private var spin = false
    @State private var showSupport = false

    private var appVersionText: String {
        let version =
            Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String
        return version?.isEmpty == false ? version ?? "1.0" : "1.0"
    }

    private var newsImage: String {
        if UIImage(named: "loading_news") != nil {
            return "loading_news"
        }
        if UIImage(named: background) != nil {
            return background
        }
        return "theme_epic"
    }

    private var tipTitle: String {
        progress < 0.5 ? "New Realm Path" : "Tips Battle"
    }

    private var tipBody: String {
        progress < 0.5
            ? "Waehle Kapitel-Nodes auf der World Map und schalte Battle-Nodes nach und nach frei."
            : "Skill Cards loesen eigene 3D-Partikel aus. Normale Taps bleiben schnelle Basisangriffe."
    }

    var body: some View {
        ZStack {

            VStack(spacing: 0) {
                topInfo

                Spacer(minLength: 24)

                centerPanel
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)

                newsBlock
                    .padding(.horizontal, 20)

                Spacer(minLength: 28)

                bottomBrand
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showSupport) {
            SupportView()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.05).repeatForever(autoreverses: false)
            ) {
                spin = true
            }
        }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    Image(theme.background)
                        .resizable()
                        .scaledToFill()
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.6),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    private var topInfo: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {

                Text("v\(appVersionText)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showSupport = true
            } label: {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.92))
                            .frame(width: 40, height: 40)
                            .shadow(
                                color: .black.opacity(0.28),
                                radius: 8,
                                y: 3
                            )

                        if UIImage(named: "support_icon") != nil {
                            Image("support_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .shadow(
                                    color: .black.opacity(0.18),
                                    radius: 2,
                                    y: 1
                                )
                        } else {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(
                                    Color(red: 0.12, green: 0.40, blue: 0.95)
                                )
                        }
                    }

                    Text("Support")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.45), radius: 3, y: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Support oeffnen")
        }
        .padding(.horizontal, 20)
    }

    private var centerPanel: some View {
        VStack(spacing: 18) {
            spinnerBlock

            VStack(spacing: 6) {
                Text("Entering Ascended Realms")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(
                    "Deine Welt, Battle-Daten und Event-Pfade werden vorbereitet."
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }

            progressBar
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
                    .shadow(color: .blue.opacity(0.75), radius: 10)
            }

            HStack(spacing: 7) {
                ForEach(Array("Loading"), id: \.self) { character in
                    Text(String(character))
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white.opacity(0.92))
                }
                Text(".")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        Color(red: 0.20, green: 0.45, blue: 1.0).opacity(0.95)
                    )
                    .opacity(progress > 0.25 ? 1 : 0.25)
                Text(".")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        Color(red: 0.20, green: 0.45, blue: 1.0).opacity(0.95)
                    )
                    .opacity(progress > 0.55 ? 1 : 0.25)
                Text(".")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        Color(red: 0.20, green: 0.45, blue: 1.0).opacity(0.95)
                    )
                    .opacity(progress > 0.82 ? 1 : 0.25)
            }
            .tracking(3)
        }
    }

    private var newsBlock: some View {
        VStack(spacing: 16) {
            Image(newsImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 128)
                .clipped()
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)

            VStack(spacing: 11) {
                Text(tipTitle)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color(red: 0.92, green: 0.77, blue: 0.36))
                    .multilineTextAlignment(.center)

                Text(tipBody)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            Color.black.opacity(0.34),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue,
                                    .blue,
                                    .white,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(
                                16,
                                geo.size.width * min(max(progress, 0), 1)
                            )
                        )
                        .shadow(
                            color: Color(red: 0.20, green: 0.45, blue: 1.0)
                                .opacity(0.45),
                            radius: 8,
                            y: 2
                        )
                }
            }
            .frame(height: 10)

            HStack {
                Text("Realm Sync")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
    }

    private var bottomBrand: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SLAYKEN ASCENDED REALMS")
                    .font(.system(size: 14, weight: .black))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.52)

                Text("Loading battle systems, events and rewards")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.50))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.black.opacity(0.30),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
    }
}

#Preview {
    LoadingOverlayView(progress: 0.62, background: "theme_epic")
        .environmentObject(ThemeManager())
}
