//
//  ScheduledOperation+CoreDataHelpers.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import CoreData
import VaultDomain

extension ScheduledOperation {
    
    /// The typed representation of the operation’s raw `type` value.
    ///
    /// This property provides a safe mapping between the stored raw value
    /// and the `RecurrenceType` enum.
    public var recurrenceType: RecurrenceType {
        get {
            return RecurrenceType(rawValue: recurrence) ?? .once
        }
        set {
            recurrence = newValue.rawValue
        }
    }
}
