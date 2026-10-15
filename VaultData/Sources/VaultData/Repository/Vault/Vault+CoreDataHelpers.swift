//
//  Vault+CoreDataHelpers.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import Foundation

// MARK: - Vault
extension Vault {
    /// The current balance of the vault.
    ///
    /// This value is calculated dynamically by combining the `initialDeposit`
    /// with all associated operations and received same-vault reimbursements.
    ///
    /// Income operations increase the balance and expense operations decrease it.
    /// Cross-vault reimbursements are already represented by linked income operations
    /// in their destination vault, so they are counted through the normal operations
    /// balance. Same-vault reimbursements do not create an income operation, so
    /// received same-vault reimbursement amounts are added back manually.
    ///
    /// - Returns: The computed balance based on the initial deposit, operations,
    ///   and received same-vault reimbursements.
    ///
    /// - Note: If the vault has no operations and no received same-vault
    ///   reimbursements, the balance equals `initialDeposit`.
    public var currentBalance: Double {
        let operations = (operations as? Set<Operation>) ?? []
        
        let operationsBalance = operations.reduce(0.0) { result, operation in
            switch operation.operationType {
            case .income:
                return result + operation.amount
            case .expense:
                return result - operation.amount
            }
        }
        
        let reimbursements = (sourceReimbursements as? Set<Reimbursement>) ?? []
        
        let sameVaultReceivedReimbursements = reimbursements
            .filter { reimbursement in
                reimbursement.reimbursementStatus == .received &&
                reimbursement.sourceVault?.id == id &&
                reimbursement.destinationVault?.id == id
            }
            .reduce(0.0) { result, reimbursement in
                result + (reimbursement.amount?.doubleValue ?? 0.0)
            }
        
        return initialDeposit + operationsBalance + sameVaultReceivedReimbursements
    }
}
