//
//  Reimbursement+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias ReimbursementCoreDataPropertiesSet = NSSet

extension Reimbursement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reimbursement> {
        return NSFetchRequest<Reimbursement>(entityName: "Reimbursement")
    }

    @NSManaged nonisolated public var amount: NSDecimalNumber?
    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var notes: String?
    @NSManaged nonisolated public var status: Int16
    @NSManaged nonisolated public var destinationCategory: Category?
    @NSManaged nonisolated public var destinationVault: Vault?
    @NSManaged nonisolated public var incomeOperation: Operation?
    @NSManaged nonisolated public var originalOperation: Operation?
    @NSManaged nonisolated public var sourceVault: Vault?

}

extension Reimbursement : Identifiable {

}
