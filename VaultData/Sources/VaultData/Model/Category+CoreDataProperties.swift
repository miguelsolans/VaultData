//
//  Category+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias CategoryCoreDataPropertiesSet = NSSet

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged nonisolated public var archived: Bool
    @NSManaged nonisolated public var budgetRole: Int16
    @NSManaged nonisolated public var color: String?
    @NSManaged nonisolated public var emoji: String?
    @NSManaged nonisolated public var hasMonthlyBudget: Bool
    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var monthlyBudget: NSDecimalNumber?
    @NSManaged nonisolated public var name: String?
    @NSManaged nonisolated public var type: Int16
    @NSManaged nonisolated public var visibleInPlot: Bool
    @NSManaged nonisolated public var mainIncomeForVault: Vault?
    @NSManaged nonisolated public var operations: NSSet?
    @NSManaged nonisolated public var reimbursements: NSSet?
    @NSManaged nonisolated public var vault: Vault?
    @NSManaged nonisolated public var scheduledOperations: NSSet?

}

// MARK: Generated accessors for operations
extension Category {

    @objc(addOperationsObject:)
    @NSManaged nonisolated public func addToOperations(_ value: Operation)

    @objc(removeOperationsObject:)
    @NSManaged nonisolated public func removeFromOperations(_ value: Operation)

    @objc(addOperations:)
    @NSManaged nonisolated public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged nonisolated public func removeFromOperations(_ values: NSSet)

}

// MARK: Generated accessors for reimbursements
extension Category {

    @objc(addReimbursementsObject:)
    @NSManaged nonisolated public func addToReimbursements(_ value: Reimbursement)

    @objc(removeReimbursementsObject:)
    @NSManaged nonisolated public func removeFromReimbursements(_ value: Reimbursement)

    @objc(addReimbursements:)
    @NSManaged nonisolated public func addToReimbursements(_ values: NSSet)

    @objc(removeReimbursements:)
    @NSManaged nonisolated public func removeFromReimbursements(_ values: NSSet)

}

// MARK: Generated accessors for scheduledOperations
extension Category {

    @objc(addScheduledOperationsObject:)
    @NSManaged nonisolated public func addToScheduledOperations(_ value: ScheduledOperation)

    @objc(removeScheduledOperationsObject:)
    @NSManaged nonisolated public func removeFromScheduledOperations(_ value: ScheduledOperation)

    @objc(addScheduledOperations:)
    @NSManaged nonisolated public func addToScheduledOperations(_ values: NSSet)

    @objc(removeScheduledOperations:)
    @NSManaged nonisolated public func removeFromScheduledOperations(_ values: NSSet)

}

extension Category : Identifiable {

}
