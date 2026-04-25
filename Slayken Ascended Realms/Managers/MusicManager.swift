//
//  MusicManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class MusicManager: NSObject, ObservableObject {
    @Published private(set) var tracks: [MusicTrackDefinition]
    @Published private(set) var currentTrackID: String?
    @Published private(set) var volume: Double
    @Published private(set) var isEnabled: Bool

    private var player: AVAudioPlayer?
    private var currentIndex = 0
    private var hasStartedPlayback = false
    private let volumeKey = "music_volume"
    private let enabledKey = "music_enabled"

    override init() {
        self.tracks = loadMusicTracks()
        let savedVolume =
            UserDefaults.standard.object(forKey: volumeKey) as? Double
        self.volume = savedVolume ?? 0.7
        let savedEnabled =
            UserDefaults.standard.object(forKey: enabledKey) as? Bool
        self.isEnabled = savedEnabled ?? true
        super.init()
        configureAudioSession()
    }

    func startPlaybackIfNeeded() {
        guard !hasStartedPlayback else { return }
        hasStartedPlayback = true
        playCurrentTrack()
    }

    func restartPlaylist() {
        currentIndex = 0
        playCurrentTrack()
    }

    func setVolume(_ newValue: Double) {
        let clampedValue = min(max(newValue, 0), 1)
        volume = clampedValue
        player?.volume = Float(clampedValue)
        UserDefaults.standard.set(clampedValue, forKey: volumeKey)
    }

    func toggleEnabled() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)

        if isEnabled {
            if hasStartedPlayback {
                playCurrentTrack()
            }
        } else {
            player?.stop()
            currentTrackID = nil
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            return
        }
    }

    private func playCurrentTrack() {
        guard isEnabled else { return }
        guard !tracks.isEmpty else { return }
        guard tracks.indices.contains(currentIndex) else {
            currentIndex = 0
            playCurrentTrack()
            return
        }

        let track = tracks[currentIndex]
        guard let url = resourceURL(for: track.fileName) else { return }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.volume = Float(volume)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            currentTrackID = track.id
        } catch {
            playNextTrack()
        }
    }

    private func playNextTrack() {
        guard !tracks.isEmpty else { return }
        currentIndex = (currentIndex + 1) % tracks.count
        playCurrentTrack()
    }

    private func resourceURL(for fileName: String) -> URL? {
        let fileExtension = (fileName as NSString).pathExtension
        let resourceName =
            fileExtension.isEmpty
            ? fileName
            : (fileName as NSString).deletingPathExtension

        return Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension.isEmpty ? nil : fileExtension
        )
    }
}

extension MusicManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            self.playNextTrack()
        }
    }
}
