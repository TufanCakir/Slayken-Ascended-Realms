//
//  EventArchiveView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import SwiftUI

struct EventArchiveView: View {
    let chapters: [GlobeEventChapter]
    let onClose: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    @State private var activeCutscene: GlobeEventCutscene?

    private var activeTheme: GameTheme? {
        theme.selectedTheme ?? theme.themes.first
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: true) {
                LazyVStack(spacing: 14) {
                    ForEach(chapters) { chapter in
                        chapterSection(chapter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
        .fullScreenCover(item: $activeCutscene) { cutscene in
            EventCutsceneView(cutscene: cutscene) {
                activeCutscene = nil
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
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

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        .white.opacity(0.13),
                        in: RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            VStack(alignment: .leading, spacing: 2) {
                Text("EVENT ARCHIVE")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                Text(
                    "Saisonale Events, Bossfights und Cutscenes erneut ansehen"
                )
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.64))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)

            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(activeTheme?.glow.color ?? .yellow)
                .frame(width: 40, height: 40)
                .background(
                    .white.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.46))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func chapterSection(_ chapter: GlobeEventChapter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title.uppercased())
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(chapter.subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }

            if let cutscene = chapter.cutscene {
                cutsceneButton(cutscene, label: "Event Cutscene")
            }

            ForEach(chapter.points) { point in
                pointSection(point)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .white.opacity(0.075),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        )
    }

    private func pointSection(_ point: GlobeEventPoint) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Image(point.resolvedNodeImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 42)
                    .clipped()
                    .overlay(
                        Rectangle().stroke(.white.opacity(0.18), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(point.title)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                    Text(point.text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(3)
                }
            }

            if let cutscene = point.cutscene {
                cutsceneButton(cutscene, label: "Node Cutscene")
            }

            ForEach(point.battles) { battle in
                battleStoryBlock(battle)
            }
        }
        .padding(11)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func battleStoryBlock(_ battle: GlobeBattle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Lv. \(battle.difficulty * 10)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(activeTheme?.glow.color ?? .yellow)
                Text(battle.name)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(battle.description)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(2)

            if let cutscene = battle.cutscene {
                cutsceneButton(cutscene, label: "Battle Cutscene")
            }

            if !battle.story.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(battle.story.enumerated()), id: \.offset) {
                        _,
                        line in
                        storyLine(line)
                    }
                }
                .padding(10)
                .background(
                    .white.opacity(0.055),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
        }
        .padding(10)
        .background(
            .white.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private func storyLine(_ line: StoryLine) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if !line.speaker.isEmpty {
                Text(line.speaker.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(activeTheme?.glow.color ?? .yellow)
            }
            Text(line.text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func cutsceneButton(
        _ cutscene: GlobeEventCutscene,
        label: String
    ) -> some View {
        Button {
            activeCutscene = cutscene
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 16, weight: .black))
                VStack(alignment: .leading, spacing: 1) {
                    Text(label.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.56))
                    Text(cutscene.title)
                        .font(.system(size: 11, weight: .black))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                (activeTheme?.primary.color ?? .white).opacity(0.18),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EventArchiveView(
        chapters: loadGlobeEventChapters().filter { $0.id.hasPrefix("event_") }
    ) {}
    .environmentObject(ThemeManager())
}
