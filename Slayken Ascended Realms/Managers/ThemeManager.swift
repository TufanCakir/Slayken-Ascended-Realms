//
//  ThemeManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 11.04.26.
//

import Combine
import Foundation

final class ThemeManager: ObservableObject {

    @Published var themes: [GameTheme] = []
    @Published var selectedTheme: GameTheme?

    private let key = "selectedThemeID"

    init() {
        loadThemes()
        loadSelected()
    }

    func loadThemes() {
        guard
            let url = Bundle.main.url(
                forResource: "themes",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(
                [GameTheme].self,
                from: data
            )
        else {
            return
        }

        themes = decoded
    }

    func select(_ theme: GameTheme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.id, forKey: key)
    }

    func loadSelected() {
        let savedID = UserDefaults.standard.integer(forKey: key)
        selectedTheme =
            themes.first(where: { $0.id == savedID }) ?? themes.first
    }
}
