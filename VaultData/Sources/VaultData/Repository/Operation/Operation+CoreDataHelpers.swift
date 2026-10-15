//
//  Operation+CoreDataHelpers.swift
//  Vault
//
//  Created by Miguel Solans on 01/04/2026.
//

import Foundation
import FoundationModels

/// Represents the type of a financial operation.
///
/// This enum distinguishes between operations from `income` and `expense`

public enum OperationType: Int16 {
    case income = 0, expense = 1
}

public enum SplittingType: Int16 {
    case none = 0, manual = 1, equal = 2
}

public enum BudgetRole: Int16 {
    case unclassified = 0
    case needs = 1
    case wants = 2
    case savings = 3
}

public enum ReimbursementStatus: Int16 {
    case expected = 0, received = 1, cancelled = 2
}

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


