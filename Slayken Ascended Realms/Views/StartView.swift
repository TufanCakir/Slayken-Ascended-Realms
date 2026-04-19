//
//  StartView.swift
//  Valtasia
//
//  Created by Tufan Cakir on 06.03.26.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var theme: ThemeManager

    let onStart: () -> Void

    @State private var animate = false
    @State private var pulse = false

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return version?.isEmpty == false ? version ?? "1.0" : "1.0."
    }

    private var copyrightYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    versionLabel
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.leading, 8)

                    Spacer(minLength: proxy.size.height * 0.16)

                    logoBlock
                        .padding(.horizontal, 18)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 16)

                    Spacer()

                    startPrompt
                        .padding(.bottom, proxy.size.height * 0.18)

                    Spacer(minLength: 24)

                    copyrightLabel
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onStart()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var versionLabel: some View {
        Text(appVersionText)
            .font(.system(size: 10, weight: .semibold, design: .serif))
            .foregroundStyle(.black.opacity(0.35))
    }

    private var logoBlock: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Color(red: 0.18, green: 0.43, blue: 0.92).opacity(0.58), lineWidth: 3)
                    .frame(width: 190, height: 190)
                    .scaleEffect(x: 1.35, y: 0.56)
                    .rotationEffect(.degrees(-8))
                    .offset(y: -2)

                Text("S")
                    .font(.system(size: 128, weight: .ultraLight, design: .serif))
                    .foregroundStyle(.black.opacity(0.14))
                    .offset(y: -58)

                HStack(spacing: 0) {
                    Text("SLAYKEN")
                    Text(" ASCENDED")
                    Text(" REALMS")
                }
                .font(.system(size: 32, weight: .light, design: .serif))
                .tracking(5)
                .foregroundStyle(.black.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.48)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)

                Rectangle()
                    .fill(Color.black.opacity(0.64))
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                    .offset(y: 28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 210)
        }
    }

    private var startPrompt: some View {
        HStack(spacing: 14) {
            decorativeLine

            Text("Zum Starten\nantippen")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black.opacity(pulse ? 0.42 : 0.20))
                .fixedSize(horizontal: true, vertical: true)

            decorativeLine
        }
        .padding(.horizontal, 28)
    }

    private var decorativeLine: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.black.opacity(0.18))
                .frame(height: 1)

            Circle()
                .fill(Color(red: 0.72, green: 0.63, blue: 0.22).opacity(0.42))
                .frame(width: 5, height: 5)
        }
        .frame(width: 94)
    }

    private var copyrightLabel: some View {
        VStack(spacing: 4) {
            Text("© \(copyrightYear) Tufan Cakir. Alle Rechte vorbehalten.")
                .font(.system(size: 10, weight: .semibold, design: .serif))

            Text("SLAYKEN ASCENDED REALMS und alle zugehörigen Namen sind Eigentum von Tufan Cakir.")
                .font(.system(size: 7, weight: .regular, design: .serif))
        }
        .foregroundStyle(.black.opacity(0.24))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
    }
}

#Preview {
    StartView(onStart: {})
        .environmentObject(GameState())
        .environmentObject(ThemeManager())
}
