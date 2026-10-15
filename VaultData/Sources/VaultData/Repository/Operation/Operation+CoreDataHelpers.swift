//
//  Operation+CoreDataHelpers.swift
//  Vault
//
//  Created by Miguel Solans on 01/04/2026.
//

import Foundation
import FoundationModels
import VaultDomain

// MARK: - Computed Properties
extension Operation {
    /// The typed representation of the operation’s raw `type` value.
    ///
    /// This property provides a safe mapping between the stored raw value
    /// and the `OperationType` enum.
    public var operationType: OperationType {
        get {
            return OperationType(rawValue: type) ?? .income // default fallback
        }
        set {
            type = newValue.rawValue
        }
    }
    
    /// The typed representation of operation's raw `splitType` value
    ///
    /// This property provides a safe mapping between the stored raw value
    /// and the `SplittingType` enum.
    public var splittingType: SplittingType {
        get {
            return SplittingType(rawValue: splitType) ?? .none
        }
        set {
            splitType = newValue.rawValue
        }
    }
}


