//
//  StoreKitShopManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 10.04.26.
//

import Combine
import Foundation
import StoreKit
import SwiftData

@MainActor
final class StoreKitShopManager: ObservableObject {
    @Published private(set) var productsByID: [String: Product] = [:]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchaseInFlightProductID: String?
    @Published var message = ""

    private var crystalPacks: [StoreCrystalPackDefinition] = []
    private var contextProvider: (() -> ModelContext?)?
    private var updatesTask: Task<Void, Never>?
    private var isConfigured = false

    deinit {
        updatesTask?.cancel()
    }

    func configure(
        packs: [StoreCrystalPackDefinition],
        contextProvider: @escaping () -> ModelContext?
    ) {
        crystalPacks = packs
        self.contextProvider = contextProvider

        guard !isConfigured else { return }
        isConfigured = true
        updatesTask = Task { [weak self] in
            await self?.monitorTransactions()
        }
    }

    func loadProducts() async {
        guard !crystalPacks.isEmpty else {
            productsByID = [:]
            return
        }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let productIDs = crystalPacks.map(\.productID)
            let products = try await Product.products(for: productIDs)
            productsByID = Dictionary(
                uniqueKeysWithValues: products.map { ($0.id, $0) }
            )
            if products.isEmpty {
                message = "Keine StoreKit Produkte gefunden."
            }
        } catch {
            message = "StoreKit Produkte konnten nicht geladen werden."
        }
    }

    func product(for pack: StoreCrystalPackDefinition) -> Product? {
        productsByID[pack.productID]
    }

    func displayPrice(for pack: StoreCrystalPackDefinition) -> String {
        product(for: pack)?.displayPrice ?? "StoreKit Setup fehlt"
    }

    func purchase(_ pack: StoreCrystalPackDefinition) async -> Bool {
        guard let product = product(for: pack) else {
            message = "StoreKit Produkt nicht verfuegbar."
            return false
        }

        purchaseInFlightProductID = pack.productID
        defer { purchaseInFlightProductID = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let granted = await grantIfNeeded(from: verification)
                if granted {
                    message = "\(pack.name) erfolgreich gekauft."
                }
                return granted
            case .pending:
                message = "Kauf ausstehend."
                return false
            case .userCancelled:
                message = "Kauf abgebrochen."
                return false
            @unknown default:
                message = "Unbekanntes StoreKit Ergebnis."
                return false
            }
        } catch {
            message = "Kauf fehlgeschlagen."
            return false
        }
    }

    private func monitorTransactions() async {
        for await verification in Transaction.unfinished {
            _ = await grantIfNeeded(from: verification)
        }

        for await verification in Transaction.updates {
            _ = await grantIfNeeded(from: verification)
        }
    }

    private func grantIfNeeded(
        from verification: VerificationResult<Transaction>
    ) async -> Bool {
        guard case .verified(let transaction) = verification else {
            message = "Unverifizierter StoreKit Kauf ignoriert."
            return false
        }

        guard let context = contextProvider?() else {
            return false
        }

        let transactionID = String(transaction.id)
        guard
            !PlayerInventoryStore.hasProcessedStoreTransaction(
                transactionID,
                in: context
            )
        else {
            await transaction.finish()
            return true
        }

        guard
            let pack = crystalPacks.first(where: {
                $0.productID == transaction.productID
            })
        else {
            await transaction.finish()
            return false
        }

        PlayerInventoryStore.add(pack.rewards, in: context)
        for characterReward in pack.characterRewards {
            PlayerInventoryStore.addOwned(
                characterID: characterReward.characterID,
                in: context
            )
        }
        for skinReward in pack.skinRewards {
            PlayerInventoryStore.addOwnedSkin(
                characterID: skinReward.characterID,
                skinID: skinReward.skinID,
                in: context
            )
        }
        for cardReward in pack.cardRewards {
            PlayerInventoryStore.addOwnedCard(
                cardID: cardReward.cardID,
                amount: cardReward.amount,
                in: context
            )
        }
        PlayerInventoryStore.markStoreTransactionProcessed(
            transactionID,
            in: context
        )
        await transaction.finish()
        return true
    }
}
