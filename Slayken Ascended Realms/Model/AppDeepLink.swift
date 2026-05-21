//
//  AppDeepLink.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import Foundation

enum AppDeepLinkDestination: Equatable {
    case home
    case event(chapterID: String?, pointID: String?, battleID: String?)
    case character
    case summon
    case shop
    case support
    case dailyLogin
    case gift
    case news
    case settings
    case quests
}

@MainActor
final class AppDeepLinkRouter: ObservableObject {
    @Published var pendingDestination: AppDeepLinkDestination?

    func open(_ url: URL) {
        guard let destination = AppDeepLinkDestination(url: url) else {
            return
        }
        pendingDestination = destination
    }

    func consumePendingDestination() {
        pendingDestination = nil
    }
}

extension AppDeepLinkDestination {
    init?(url: URL) {
        guard
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        else {
            return nil
        }

        let scheme = components.scheme?.lowercased()
        let isSupportedScheme =
            scheme == "slayken" || scheme == "slaykenascendedrealms"
            || scheme == "https" || scheme == "http"

        guard isSupportedScheme else { return nil }

        let host = components.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let query = Dictionary(
            uniqueKeysWithValues: components.queryItems?.compactMap {
                item -> (String, String)? in
                guard let value = item.value, !value.isEmpty else {
                    return nil
                }
                return (item.name.lowercased(), value)
            } ?? []
        )

        let route: String?
        let values: [String]
        if scheme == "http" || scheme == "https" {
            route = pathComponents.first?.lowercased()
            values = Array(pathComponents.dropFirst())
        } else {
            route = host ?? pathComponents.first?.lowercased()
            values =
                host == nil ? Array(pathComponents.dropFirst()) : pathComponents
        }

        switch route {
        case "home", "game":
            self = .home
        case "event", "events":
            self = .event(
                chapterID: query["chapter"] ?? values.first,
                pointID: query["point"] ?? values.dropFirst().first,
                battleID: query["battle"]
            )
        case "battle":
            self = .event(
                chapterID: query["chapter"],
                pointID: query["point"],
                battleID: query["id"] ?? query["battle"] ?? values.first
            )
        case "character":
            self = .character
        case "summon":
            self = .summon
        case "shop":
            self = .shop
        case "support":
            self = .support
        case "daily-login", "daily_login", "login":
            self = .dailyLogin
        case "gift", "gifts":
            self = .gift
        case "news":
            self = .news
        case "settings":
            self = .settings
        case "quests":
            self = .quests
        default:
            return nil
        }
    }
}
