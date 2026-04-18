//
//  EventCutsceneView.swift
//  Slayken Ascended Realms
//

import AVKit
import SwiftUI

struct EventCutsceneView: View {
    let cutscene: GlobeEventCutscene
    let onFinish: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.94)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text(cutscene.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Button(action: finish) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.16), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 52)

                cutsceneContent
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                    .padding(.horizontal, 18)

                if let text = cutscene.text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.86))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }

                Button(action: finish) {
                    Label("Weiter", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.black.opacity(0.78))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(.white.opacity(0.92), in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 18)
            }
        }
        .onAppear(perform: startPlayback)
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @ViewBuilder
    private var cutsceneContent: some View {
        if let player {
            VideoPlayer(player: player)
                .background(Color.black)
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.06, blue: 0.08),
                        Color(red: 0.24, green: 0.28, blue: 0.34),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 44, weight: .light))
                    Text("MP4 fehlt")
                        .font(.system(size: 12, weight: .black))
                }
                .foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private func startPlayback() {
        guard let url = cutsceneVideoURL() else { return }
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()
    }

    private func cutsceneVideoURL() -> URL? {
        guard let video = cutscene.video, !video.isEmpty else { return nil }

        if let url = Bundle.main.url(forResource: video, withExtension: nil) {
            return url
        }

        if let url = Bundle.main.url(forResource: video, withExtension: "mp4") {
            return url
        }

        return nil
    }

    private func finish() {
        player?.pause()
        onFinish()
    }
}
