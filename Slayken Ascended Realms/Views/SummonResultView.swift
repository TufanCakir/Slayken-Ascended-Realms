//
//  SummonResultView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct SummonResultView: View {
    let result: SummonDrop
    var onClose: (() -> Void)? = nil

    @EnvironmentObject var theme: ThemeManager

    @State private var animate = false

    private var title: String {
        switch result {
        case .character:
            return "Character Summoned"
        case .skin:
            return "Skin Unlocked"
        case .card:
            return "Skill Card Summoned"
        }
    }

    private var name: String {
        switch result {
        case .character(let character):
            return character.name
        case .skin(_, let skin):
            return skin.name
        case .card(let card):
            return card.name
        }
    }

    private var imageName: String {
        switch result {
        case .character(let character):
            return character.summonImage
        case .skin(_, let skin):
            return skin.summonImage ?? skin.texture
        case .card(let card):
            return card.image
        }
    }

    private var stars: Int {
        switch result {
        case .character(let character):
            return character.rarity
        case .skin:
            return 5
        case .card(let card):
            return card.resolvedRarity
        }
    }

    var body: some View {

        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))

                rarityStars

                Text(name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 4, y: 2)

                resultImage
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
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(
                    .ultraThinMaterial.opacity(0.6)
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(
                    .white.opacity(0.3),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.6), radius: 12, y: 6)

            Spacer()

            Button(action: { onClose?() }) {
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
                        Capsule().stroke(.white.opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 40)
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
        .background {
            ZStack {
                if let theme = theme.selectedTheme {
                    RemoteAssetImage(theme.background) {
                        Color.black.opacity(0.35)
                    }
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

    private var rarityStars: some View {
        HStack(spacing: 4) {
            ForEach(0..<stars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .shadow(color: .black, radius: 2, y: 1)
            }
        }
    }

    private var resultImage: some View {
        Group {
            RemoteAssetImage(imageName, contentMode: .fit) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.white.opacity(0.68))
                    .padding(44)
            }
        }
    }
}

struct SummonResultsView: View {
    let results: [SummonDrop]
    var onClose: (() -> Void)? = nil

    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 12) {
                Text(results.count > 1 ? "Multi Summon" : "Summon Result")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))

                ScrollView(showsIndicators: true) {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 96), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(Array(results.enumerated()), id: \.offset) {
                            _,
                            result in
                            resultCard(result)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 430)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(
                    .ultraThinMaterial.opacity(0.6)
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(
                    .white.opacity(0.3),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
            .padding(.horizontal, 16)

            Button(action: { onClose?() }) {
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
                        Capsule().stroke(.white.opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func resultCard(_ result: SummonDrop) -> some View {
        VStack(spacing: 7) {
            RemoteAssetImage(imageName(for: result), contentMode: .fit) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(width: 80, height: 80)

            Text(stars(for: result))
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.yellow)

            Text(name(for: result))
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            .black.opacity(0.32),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func name(for result: SummonDrop) -> String {
        switch result {
        case .character(let character):
            return character.name
        case .skin(_, let skin):
            return skin.name
        case .card(let card):
            return card.name
        }
    }

    private func imageName(for result: SummonDrop) -> String {
        switch result {
        case .character(let character):
            return character.summonImage
        case .skin(_, let skin):
            return skin.summonImage ?? skin.texture
        case .card(let card):
            return card.image
        }
    }

    private func stars(for result: SummonDrop) -> String {
        let count: Int
        switch result {
        case .character(let character):
            count = character.rarity
        case .skin:
            count = 5
        case .card(let card):
            count = card.resolvedRarity
        }
        return String(repeating: "★", count: max(1, count))
    }
}
