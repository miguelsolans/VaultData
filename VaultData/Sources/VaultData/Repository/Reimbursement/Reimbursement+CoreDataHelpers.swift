//
//  Reimbursement.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import VaultDomain

// MARK: - Reimbursement
extension Reimbursement {
    /// The typed representation of the reimbursement’s raw `type` value.
    ///
    /// This property provides a safe mapping between the stored raw value
    /// and the `ReimbursementStatus` enum.
    public var reimbursementStatus: ReimbursementStatus {
        get {
            return ReimbursementStatus(rawValue: status) ?? .expected
        }
        set {
            status = newValue.rawValue
        }
    }
    
    public var isSameVault: Bool {
        get {
            return destinationVault?.id == sourceVault?.id
        }
    }
}
