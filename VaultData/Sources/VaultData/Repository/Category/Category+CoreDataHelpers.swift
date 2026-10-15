//
//  Category+CoreDataHelpers.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import Foundation

extension Category {
    /// The typed representation of the category’s raw `type` value.
    ///
    /// This property maps the stored raw value to an `OperationType`,
    /// allowing categories to be associated with either income or expense operations.
    public var operationType: OperationType {
        get {
            return OperationType(rawValue: type) ?? .income // default fallback
        }
        set {
            type = newValue.rawValue
        }
    }
}


extension Category {
    /// The typed representation of the category’s raw `budgetRole` value.
    ///
    /// This property maps the stored raw value to an `BudgetRole`,
    /// allowing categories to be classified to 50/30/20 rule.
    public var budgetRoleType: BudgetRole {
        get {
            return BudgetRole(rawValue: type) ?? .unclassified
        }
        set {
            budgetRole = newValue.rawValue
        }
    }
}
