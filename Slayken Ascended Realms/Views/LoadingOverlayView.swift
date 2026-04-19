//
//  LoadingOverlayView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 13.04.26.
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
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version?.isEmpty == false ? version ?? "1.0" : "1.0."
    }

    private var newsImage: String {
        if UIImage(named: "loading_news") != nil {
            return "loading_news"
        }
        if UIImage(named: background) != nil {
            return background
        }
        return "sar_bg"
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
            backgroundLayer

            VStack(spacing: 0) {
                topInfo

                Spacer(minLength: 18)

                spinnerBlock
                    .padding(.top, 10)

                Spacer(minLength: 20)

                newsBlock
                    .padding(.horizontal, 36)

                Spacer(minLength: 28)

                bottomBrand
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showSupport) {
            SupportView()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                spin = true
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(red: 0.12, green: 0.15, blue: 0.22)
                .ignoresSafeArea()

            Image(newsImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.12)
                .blur(radius: 1.2)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color(red: 0.10, green: 0.13, blue: 0.20).opacity(0.92),
                    Color.black.opacity(0.18),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image(systemName: "sparkles")
                .font(.system(size: 210, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.055))
                .offset(y: -120)
        }
    }

    private var topInfo: some View {
        HStack(alignment: .top) {
            Text(appVersionText)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)

            Spacer()

            Button {
                showSupport = true
            } label: {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.92))
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.28), radius: 8, y: 3)

                        if UIImage(named: "support_icon") != nil {
                            Image("support_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        } else {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(Color(red: 0.12, green: 0.40, blue: 0.95))
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
        .padding(.horizontal, 100)
    }

    private var spinnerBlock: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.34), lineWidth: 7)
                    .frame(width: 58, height: 58)

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        AngularGradient(
                            colors: [
                                .cyan.opacity(0.0),
                                .cyan.opacity(0.95),
                                .white.opacity(0.86),
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .shadow(color: .cyan.opacity(0.75), radius: 10)
            }

            HStack(spacing: 9) {
                ForEach(Array("Loading"), id: \.self) { character in
                    Text(String(character))
                        .font(.system(size: 19, weight: .light))
                        .foregroundStyle(.white.opacity(0.78))
                }
                Text(".")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.white.opacity(0.78))
                    .opacity(progress > 0.25 ? 1 : 0.25)
                Text(".")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.white.opacity(0.78))
                    .opacity(progress > 0.55 ? 1 : 0.25)
                Text(".")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.white.opacity(0.78))
                    .opacity(progress > 0.82 ? 1 : 0.25)
            }
            .tracking(8)
        }
    }

    private var newsBlock: some View {
        VStack(spacing: 16) {
            Image(newsImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 330)
                .frame(height: 112)
                .clipped()
                .overlay(Rectangle().stroke(.white.opacity(0.55), lineWidth: 2))
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

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

                progressBar
                    .padding(.top, 8)
            }
            .frame(maxWidth: 330)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.46))
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .white.opacity(0.86)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(16, geo.size.width * min(max(progress, 0), 1)))
                }
            }
            .frame(height: 7)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var bottomBrand: some View {
        Text("SLAYKEN ASCENDED REALMS")
            .font(.system(size: 15, weight: .medium))
            .tracking(6)
            .foregroundStyle(.white.opacity(0.48))
            .lineLimit(1)
            .minimumScaleFactor(0.52)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    LoadingOverlayView(progress: 0.62, background: "sar_bg")
        .environmentObject(ThemeManager())
}
