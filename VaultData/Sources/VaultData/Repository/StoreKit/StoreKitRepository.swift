//
//  StoreKitRepository.swift
//  VaultCore
//
//  Created by Miguel Solans on 14/06/2026.
//

import StoreKit

public enum StoreKitError: LocalizedError {
    case subscriptionRequired
    
    public var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return "Feature requires subscription"
        }
    }
}


public final class StoreKitRepository {
    
    private let productIDs: [String] = {
        [
            "com.vault.subscription.monthly",
            "com.vault.subscription.yearly",
            "com.vault.premium.lifetime"
        ]
    }()
    
    private let lifetimeProductID: String = {
        "com.vault.premium.lifetime"
    }()
    
    public func fetchProducts() async throws -> [Product] {
        return try await Product.products(for: productIDs)
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        
        if await hasPremiumAccess() {
            return false
        }
        
        let result = try await product.purchase()
        
        switch result {
            
        case .success(let verification):
            
            switch verification {
            case .verified:
                return true
                
            case .unverified:
                return false
            }
            
        case .pending:
            return false
            
        case .userCancelled:
            return false
            
        @unknown default:
            return false
        }
    }
    
    public func purchaseLifetime() async throws -> Bool {
        if await hasPremiumAccess() {
            return false
        }
        
        let result = try await Product.products(for: [lifetimeProductID]).first?.purchase()
        
        switch result {
            
        case .success(let verification):
            
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return true
                
            case .unverified(let transaction, let error):
                await transaction.finish()
                return false
            }
            
        case .pending:
            return false
            
        case .userCancelled:
            return false
            
        @unknown default:
            return false
        }
    }
    
    public func hasPremiumAccess() async -> Bool {
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }
            
            return true
        }
        
        return false
    }
    
    public func restorePurchases() async {
        try? await AppStore.sync()
    }
}
