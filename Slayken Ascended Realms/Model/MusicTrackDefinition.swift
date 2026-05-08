//
//  MusicTrackDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct MusicTrackDefinition: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let fileName: String
}

func loadMusicTracks() -> [MusicTrackDefinition] {
    JSONResourceLoader.loadMergedIdentifiableArrays(
        MusicTrackDefinition.self,
        baseResources: ["music"],
        autoDiscoveredWhere: {
            $0.hasPrefix("music_") || $0.hasPrefix("music_tracks_")
        }
    )
}
