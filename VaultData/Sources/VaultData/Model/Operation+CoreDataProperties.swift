//
//  Operation+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias OperationCoreDataPropertiesSet = NSSet

extension Operation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Operation> {
        return NSFetchRequest<Operation>(entityName: "Operation")
    }

    @NSManaged nonisolated public var amount: Double
    @NSManaged nonisolated public var date: Date?
    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var splitType: Int16
    @NSManaged nonisolated public var subtitle: String?
    @NSManaged nonisolated public var title: String?
    @NSManaged nonisolated public var type: Int16
    @NSManaged nonisolated public var createdAt: Date?
    @NSManaged nonisolated public var updatedAt: Date?
    @NSManaged nonisolated public var scheduledDate: Date?
    @NSManaged nonisolated public var category: Category?
    @NSManaged nonisolated public var reimbursements: NSSet?
    @NSManaged nonisolated public var reimbursementSource: Reimbursement?
    @NSManaged nonisolated public var vault: Vault?
    @NSManaged nonisolated public var scheduledOperation: ScheduledOperation?

}

// MARK: Generated accessors for reimbursements
extension Operation {

    @objc(addReimbursementsObject:)
    @NSManaged nonisolated public func addToReimbursements(_ value: Reimbursement)

    @objc(removeReimbursementsObject:)
    @NSManaged nonisolated public func removeFromReimbursements(_ value: Reimbursement)

    @objc(addReimbursements:)
    @NSManaged nonisolated public func addToReimbursements(_ values: NSSet)

    @objc(removeReimbursements:)
    @NSManaged nonisolated public func removeFromReimbursements(_ values: NSSet)

}

extension Operation : Identifiable {

}
