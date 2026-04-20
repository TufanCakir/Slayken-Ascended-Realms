//
//  CurrencyDefinition.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Foundation

struct CurrencyDefinition: Codable, Identifiable, Equatable {
    let code: String
    let name: String
    let icon: String
    let assetIcon: String?
    let sortOrder: Int

    var id: String { code }
}

struct CurrencyAmount: Codable, Identifiable, Equatable {
    let currency: String
    let amount: Int

    var id: String { currency }
}

func loadCurrencyDefinitions() -> [CurrencyDefinition] {
    JSONResourceLoader.loadArray(
        CurrencyDefinition.self,
        resource: "currencies"
    )
    .sorted { $0.sortOrder < $1.sortOrder }
}
