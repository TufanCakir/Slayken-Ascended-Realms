//
//  EventCutsceneView.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import AVKit
import SwiftUI

struct EventCutsceneView: View {
    let cutscene: GlobeEventCutscene
    let onFinish: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            // 🔥 FULLSCREEN VIDEO
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                fallbackView
            }

            // 🔥 UI OVERLAY
            VStack {
                HStack {
                    Text(cutscene.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white)

                    Spacer()

                    Button(action: finish) {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.5), in: Circle())
                    }
                }
                .padding()

                Spacer()

                if let text = cutscene.text, !text.isEmpty {
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
            // Remove any observers tied to the previous player item
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }

    // 🔧 FALLBACK wenn kein Video da ist
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
                Text("MP4 fehlt")
                    .font(.system(size: 12, weight: .black))
            }
            .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func startPlayback() {
        guard let url = cutsceneVideoURL() else { return }
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()

        // 🔥 Auto-Finish wenn Video endet
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            finish()
        }
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
