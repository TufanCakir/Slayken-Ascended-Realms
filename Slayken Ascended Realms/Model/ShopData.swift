//
//  ShopData.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct ShopOfferDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String?
    let category: String?
    let image: String
    let cost: [CurrencyAmount]
    let rewards: [CurrencyAmount]
    let maxPurchases: Int?
}

struct ShopSkinOfferDefinition: Codable, Identifiable, Equatable {
    let id: String
    let characterID: String
    let skinID: String
    let name: String
    let subtitle: String?
    let image: String
    let texture: String
    let cost: [CurrencyAmount]
    let maxPurchases: Int?
}

struct StorePackCharacterReward: Codable, Identifiable, Equatable {
    let characterID: String

    var id: String { characterID }
}

struct StorePackSkinReward: Codable, Identifiable, Equatable {
    let characterID: String
    let skinID: String

    var id: String { "\(characterID):\(skinID)" }
}

struct StorePackCardReward: Codable, Identifiable, Equatable {
    let cardID: String
    let amount: Int

    var id: String { cardID }
}

struct StoreCrystalPackDefinition: Codable, Identifiable, Equatable {
    let id: String
    let productID: String
    let name: String
    let subtitle: String?
    let image: String
    let rewards: [CurrencyAmount]
    let characterRewards: [StorePackCharacterReward]
    let skinRewards: [StorePackSkinReward]
    let cardRewards: [StorePackCardReward]

    init(
        id: String,
        productID: String,
        name: String,
        subtitle: String?,
        image: String,
        rewards: [CurrencyAmount],
        characterRewards: [StorePackCharacterReward] = [],
        skinRewards: [StorePackSkinReward] = [],
        cardRewards: [StorePackCardReward] = []
    ) {
        self.id = id
        self.productID = productID
        self.name = name
        self.subtitle = subtitle
        self.image = image
        self.rewards = rewards
        self.characterRewards = characterRewards
        self.skinRewards = skinRewards
        self.cardRewards = cardRewards
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case productID
        case name
        case subtitle
        case image
        case rewards
        case characterRewards
        case skinRewards
        case cardRewards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        productID = try container.decode(String.self, forKey: .productID)
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        image = try container.decode(String.self, forKey: .image)
        rewards =
            try container.decodeIfPresent(
                [CurrencyAmount].self,
                forKey: .rewards
            ) ?? []
        characterRewards =
            try container.decodeIfPresent(
                [StorePackCharacterReward].self,
                forKey: .characterRewards
            ) ?? []
        skinRewards =
            try container.decodeIfPresent(
                [StorePackSkinReward].self,
                forKey: .skinRewards
            ) ?? []
        cardRewards =
            try container.decodeIfPresent(
                [StorePackCardReward].self,
                forKey: .cardRewards
            ) ?? []
    }
}

func loadShopOffers() -> [ShopOfferDefinition] {
    JSONResourceLoader.loadArray(
        ShopOfferDefinition.self,
        resource: "shop_offers"
    )
}

func loadShopSkinOffers() -> [ShopSkinOfferDefinition] {
    JSONResourceLoader.loadArray(
        ShopSkinOfferDefinition.self,
        resource: "shop_skins"
    )
}

func loadStoreCrystalPacks() -> [StoreCrystalPackDefinition] {
    JSONResourceLoader.loadArray(
        StoreCrystalPackDefinition.self,
        resource: "store_crystal_packs"
    )
}
