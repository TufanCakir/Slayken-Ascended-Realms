//
//  StoryView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct StoryView: View {
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var theme: ThemeManager

    let story: [StoryLine]
    let onFinish: () -> Void

    @State private var currentIndex = 0

    private var currentLine: StoryLine? {
        guard story.indices.contains(currentIndex) else { return nil }
        return story[currentIndex]
    }

    private var isLastLine: Bool {
        currentIndex >= max(story.count - 1, 0)
    }

    var body: some View {
        ZStack {
            comicBackdrop

            if let currentLine {
                VStack(spacing: 14) {
                    header
                    comicPanel(for: currentLine)
                    controls
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 22)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            next()
        }
    }

    private var comicBackdrop: some View {
        ZStack {
            Color.black.opacity(0.74)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    (theme.selectedTheme?.primary.color ?? .cyan).opacity(0.34),
                    Color.black.opacity(0.86),
                ],
                center: .topLeading,
                startRadius: 40,
                endRadius: 520
            )
            .ignoresSafeArea()

            ComicDots()
                .stroke(.white.opacity(0.07), lineWidth: 1)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("STORY")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(theme.selectedTheme?.glow.color ?? .yellow)
                .clipShape(Capsule())

            Text("\(currentIndex + 1)/\(max(story.count, 1))")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white.opacity(0.82))

            Spacer()
        }
    }

    private func comicPanel(for line: StoryLine) -> some View {
        let portraitOnRight = currentIndex % 2 == 1

        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.10, blue: 0.20).opacity(
                                0.96
                            ),
                            Color(red: 0.02, green: 0.04, blue: 0.10).opacity(
                                0.98
                            ),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.52), radius: 22, y: 10)

            HStack(alignment: .bottom, spacing: 0) {
                if !portraitOnRight {
                    characterPortrait(for: line, mirrored: false)
                    Spacer(minLength: 0)
                }

                speechBubble(for: line, pointsRight: !portraitOnRight)
                    .frame(maxWidth: 250)
                    .padding(.bottom, 24)

                if portraitOnRight {
                    Spacer(minLength: 0)
                    characterPortrait(for: line, mirrored: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .frame(maxWidth: 390, minHeight: 430)
    }

    private func characterPortrait(for line: StoryLine, mirrored: Bool)
        -> some View
    {
        let portraitName = portraitImageName(for: line)

        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.38))
                .frame(width: 150, height: 38)
                .blur(radius: 2)
                .offset(y: 8)

            RemoteAssetImage(portraitName, contentMode: .fit) {
                fallbackPortrait
            }
            .frame(width: 176, height: 330)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .shadow(color: .black.opacity(0.58), radius: 16, y: 8)
        }
        .frame(width: 168, height: 350)
    }

    private var fallbackPortrait: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white.opacity(0.18),
                    .white.opacity(0.05),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "person.fill")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(.white.opacity(0.52))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func speechBubble(for line: StoryLine, pointsRight: Bool)
        -> some View
    {
        VStack(alignment: .leading, spacing: 10) {
            Text(line.speaker.uppercased())
                .font(.system(size: 12, weight: .black, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(theme.selectedTheme?.glow.color ?? .yellow)

            Text(line.text)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .lineSpacing(3)
                .foregroundStyle(.black.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            ZStack(alignment: pointsRight ? .bottomTrailing : .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.white)
                SpeechBubbleTail(pointsRight: pointsRight)
                    .fill(.white)
                    .frame(width: 34, height: 28)
                    .offset(x: pointsRight ? 18 : -18, y: 8)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.black.opacity(0.22), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.24), radius: 8, y: 4)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(story.indices, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == currentIndex
                                ? (theme.selectedTheme?.glow.color ?? .yellow)
                                : .white.opacity(0.26)
                        )
                        .frame(width: index == currentIndex ? 18 : 7, height: 7)
                }
            }

            Spacer()

            Button {
                next()
            } label: {
                Text(isLastLine ? "Start" : "Weiter")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(theme.selectedTheme?.glow.color ?? .yellow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: 390)
    }

    private func portraitImageName(for line: StoryLine) -> String {
        if let image = line.image?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ),
            !image.isEmpty
        {
            return image
        }

        let speaker = line.speaker
        let normalizedSpeaker = normalizedKey(speaker)

        if normalizedSpeaker == normalizedKey(gameState.player.name) {
            return gameState.player.image
        }

        if let summon = gameState.summonCharacters.first(where: {
            normalizedKey($0.name) == normalizedSpeaker
                || normalizedKey($0.id) == normalizedSpeaker
                || normalizedKey($0.model) == normalizedSpeaker
        }) {
            return summon.summonImage
        }

        return "preview_\(normalizedSpeaker)"
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    private func next() {
        if currentIndex < story.count - 1 {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                currentIndex += 1
            }
        } else {
            onFinish()
        }
    }
}

private struct SpeechBubbleTail: Shape {
    let pointsRight: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if pointsRight {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

private struct ComicDots: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 22
        let radius: CGFloat = 2

        var y = rect.minY
        while y <= rect.maxY {
            var x = rect.minX
            while x <= rect.maxX {
                path.addEllipse(
                    in: CGRect(
                        x: x,
                        y: y,
                        width: radius,
                        height: radius
                    )
                )
                x += spacing
            }
            y += spacing
        }

        return path
    }
}
