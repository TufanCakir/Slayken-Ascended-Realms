//
//  NewsItemDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct NewsItemDefinition: Codable, Identifiable, Equatable {
    let id: String
    let category: String
    let title: String
    let subtitle: String
    let image: String
    let date: String
    let tags: [String]
    let body: String
}

func loadNewsItems() -> [NewsItemDefinition] {
    let manualItems = JSONResourceLoader.loadMergedIdentifiableArrays(
        NewsItemDefinition.self,
        baseResources: ["news_items"],
        autoDiscoveredWhere: {
            $0.hasPrefix("news_items_") || $0.hasPrefix("news_")
        }
    )

    return mergeNewsItems(
        manualItems + generatedNewsItems()
    )
    .sorted { lhs, rhs in
        lhs.date == rhs.date ? lhs.title < rhs.title : lhs.date > rhs.date
    }
}

private func generatedNewsItems() -> [NewsItemDefinition] {
    generatedEventNews()
        + generatedLoginNews()
        + generatedSummonNews()
        + generatedShopNews()
}

private func mergeNewsItems(_ items: [NewsItemDefinition])
    -> [NewsItemDefinition]
{
    var orderedIDs = [String]()
    var itemsByID = [String: NewsItemDefinition]()

    for item in items {
        if itemsByID.updateValue(item, forKey: item.id) == nil {
            orderedIDs.append(item.id)
        }
    }

    return orderedIDs.compactMap { itemsByID[$0] }
}

private func generatedEventNews() -> [NewsItemDefinition] {
    loadGlobeEventChapters()
        .filter(\.isEventChapter)
        .map { chapter in
            NewsItemDefinition(
                id: "auto_event_\(chapter.id)",
                category: "Events",
                title: chapter.title,
                subtitle: chapter.subtitle,
                image: chapter.mapTexture,
                date: newsDate(from: chapter.endsAt),
                tags: ["Auto", "Event"],
                body: eventBody(
                    title: chapter.title,
                    subtitle: chapter.subtitle,
                    endsAt: chapter.endsAt
                )
            )
        }
}

private func generatedLoginNews() -> [NewsItemDefinition] {
    loadLoginRewardCampaigns()
        .filter { $0.id != "daily_login" }
        .map { campaign in
            NewsItemDefinition(
                id: "auto_login_\(campaign.id)",
                category: "Logins",
                title: campaign.title,
                subtitle: campaign.subtitle,
                image: firstRewardBackground(in: campaign.rewards),
                date: newsDate(from: campaign.endsAt),
                tags: ["Auto", "Login"],
                body: eventBody(
                    title: campaign.title,
                    subtitle: campaign.subtitle,
                    endsAt: campaign.endsAt
                )
            )
        }
}

private func generatedSummonNews() -> [NewsItemDefinition] {
    loadSummonBanners().map { banner in
        NewsItemDefinition(
            id: "auto_summon_\(banner.id)",
            category: "Summon",
            title: banner.name,
            subtitle: banner.subtitle ?? "Neuer Summon-Banner verfuegbar",
            image: banner.image,
            date: "Neu",
            tags: ["Auto", "Summon"],
            body: banner.subtitle
                ?? "Dieser Banner wurde aus summon_banners.json automatisch in den News angezeigt."
        )
    }
}

private func generatedShopNews() -> [NewsItemDefinition] {
    let shopOffers = loadShopOffers().map { offer in
        NewsItemDefinition(
            id: "auto_shop_\(offer.id)",
            category: "Shop",
            title: offer.name,
            subtitle: offer.subtitle ?? "Neues Shop-Angebot verfuegbar",
            image: offer.image,
            date: "Neu",
            tags: ["Auto", "Shop"],
            body: offer.subtitle
                ?? "Dieses Angebot wurde aus shop_offers.json automatisch in den News angezeigt."
        )
    }

    let skinOffers = loadShopSkinOffers().map { offer in
        NewsItemDefinition(
            id: "auto_shop_skin_\(offer.id)",
            category: "Shop",
            title: offer.name,
            subtitle: offer.subtitle ?? "Neuer Skin verfuegbar",
            image: offer.image,
            date: "Neu",
            tags: ["Auto", "Skin", "Shop"],
            body: offer.subtitle
                ?? "Dieser Skin wurde aus shop_skins.json automatisch in den News angezeigt."
        )
    }

    let crystalPacks = loadStoreCrystalPacks().map { pack in
        NewsItemDefinition(
            id: "auto_crystal_pack_\(pack.id)",
            category: "Shop",
            title: pack.name,
            subtitle: pack.subtitle ?? "Neues Crystal-Pack verfuegbar",
            image: pack.image,
            date: "Neu",
            tags: ["Auto", "Shop"],
            body: pack.subtitle
                ?? "Dieses Pack wurde aus store_crystal_packs.json automatisch in den News angezeigt."
        )
    }

    let coopOffers = loadCoopShopOffers().map { offer in
        NewsItemDefinition(
            id: "auto_coop_shop_\(offer.id)",
            category: "Shop",
            title: offer.name,
            subtitle: offer.subtitle ?? "Neues Coop-Angebot verfuegbar",
            image: offer.image,
            date: "Neu",
            tags: ["Auto", "Coop", "Shop"],
            body: offer.subtitle
                ?? "Dieses Coop-Angebot wurde aus shop_coop_offers.json automatisch in den News angezeigt."
        )
    }

    return shopOffers + skinOffers + crystalPacks + coopOffers
}

private func firstRewardBackground(in rewards: [DailyLoginRewardDefinition])
    -> String
{
    rewards.first {
        ($0.background ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false
    }?.background ?? "festival_new_year"
}

private func eventBody(
    title: String,
    subtitle: String,
    endsAt: String?
) -> String {
    if let timingText = EventDateSupport.displayText(endsAt: endsAt) {
        return "\(subtitle)\n\n\(timingText)"
    }

    return subtitle.isEmpty ? title : subtitle
}

private func newsDate(from endsAt: String?) -> String {
    guard
        let endsAt,
        let endDate = EventDateSupport.parseEndDate(from: endsAt)
    else {
        return "Neu"
    }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "de_DE_POSIX")
    formatter.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: endDate)
}
