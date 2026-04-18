//
//  SummonResultView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 18.04.26.
//

import SwiftUI

struct SummonResultView: View {
    let character: SummonCharacter
    var onClose: (() -> Void)? = nil

    @State private var animate = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {

                Spacer()

                VStack(spacing: 12) {

                    Text("You Summoned")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))

                    rarityStars

                    Text(character.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 4, y: 2)

                    characterImage
                        .frame(width: 220, height: 220)
                        .scaleEffect(animate ? 1 : 0.7)
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: animate
                        )
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.6))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.6), radius: 12, y: 6)

                Spacer()

                Button(action: {
                    onClose?()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.40, blue: 0.57),
                                    Color(red: 0.05, green: 0.18, blue: 0.32),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 40)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }

    // MARK: - Components

    private var rarityStars: some View {
        HStack(spacing: 4) {
            ForEach(0..<character.rarity, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .shadow(color: .black, radius: 2, y: 1)
            }
        }
    }

    private var characterImage: some View {
        Group {
            if UIImage(named: character.summonImage) != nil {
                Image(character.summonImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "person.crop.square")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(40)
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.12, green: 0.16, blue: 0.18),
                    Color.black,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 300)
                .blur(radius: 80)
                .scaleEffect(animate ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: animate
                )
        }
    }
}
