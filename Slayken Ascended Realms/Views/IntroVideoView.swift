//
//  IntroVideoView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import AVKit
import SwiftUI

struct IntroVideoView: View {
    let introVideo: IntroVideoDefinition
    let onFinish: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                fallbackView
            }

            VStack {
                HStack {
                    Text(introVideo.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: finish) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                if let text = introVideo.text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }

                Button(action: finish) {
                    Text("Weiter")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .background(Color.clear)
        .presentationBackground(.clear)
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear(perform: startPlayback)
        .onDisappear {
            player?.pause()
            player = nil
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }

    private var fallbackView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.24, green: 0.28, blue: 0.34),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "film.stack")
                    .font(.system(size: 44, weight: .light))
                Text("Intro Video fehlt")
                    .font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func startPlayback() {
        guard let url = introVideoURL() else { return }
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            finish()
        }
    }

    private func introVideoURL() -> URL? {
        if let url = Bundle.main.url(
            forResource: introVideo.video,
            withExtension: nil
        ) {
            return url
        }

        let name = (introVideo.video as NSString).deletingPathExtension
        let ext = (introVideo.video as NSString).pathExtension
        guard !name.isEmpty else { return nil }
        return Bundle.main.url(
            forResource: name,
            withExtension: ext.isEmpty ? "mp4" : ext
        )
    }

    private func finish() {
        player?.pause()
        onFinish()
    }
}

#Preview {
    IntroVideoView(
        introVideo: loadIntroVideoDefinitions().first
            ?? IntroVideoDefinition(
                id: "preview",
                flow: "opening",
                order: 1,
                title: "Intro",
                text: "Preview",
                video: "intro.mp4"
            ),
        onFinish: {}
    )
}
