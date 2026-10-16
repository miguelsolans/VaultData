//
//  Vault+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias VaultCoreDataPropertiesSet = NSSet

extension Vault {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vault> {
        return NSFetchRequest<Vault>(entityName: "Vault")
    }

    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var initialDeposit: Double
    @NSManaged nonisolated public var title: String?
    @NSManaged nonisolated public var categories: NSSet?
    @NSManaged nonisolated public var currencyRelation: Currency?
    @NSManaged nonisolated public var dashboard: Dashboard?
    @NSManaged nonisolated public var destinationReimbursements: NSSet?
    @NSManaged nonisolated public var favoritedBySettings: Settings?
    @NSManaged nonisolated public var mainIncomeCategory: Category?
    @NSManaged nonisolated public var operations: NSSet?
    @NSManaged nonisolated public var sourceReimbursements: NSSet?
    @NSManaged nonisolated public var scheduledOperations: NSSet?

}

// MARK: Generated accessors for categories
extension Vault {

    @objc(addCategoriesObject:)
    @NSManaged nonisolated public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged nonisolated public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged nonisolated public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged nonisolated public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for destinationReimbursements
extension Vault {

    @objc(addDestinationReimbursementsObject:)
    @NSManaged nonisolated public func addToDestinationReimbursements(_ value: Reimbursement)

    @objc(removeDestinationReimbursementsObject:)
    @NSManaged nonisolated public func removeFromDestinationReimbursements(_ value: Reimbursement)

    @objc(addDestinationReimbursements:)
    @NSManaged nonisolated public func addToDestinationReimbursements(_ values: NSSet)

    @objc(removeDestinationReimbursements:)
    @NSManaged nonisolated public func removeFromDestinationReimbursements(_ values: NSSet)

}

// MARK: Generated accessors for operations
extension Vault {

    @objc(addOperationsObject:)
    @NSManaged nonisolated public func addToOperations(_ value: Operation)

    @objc(removeOperationsObject:)
    @NSManaged nonisolated public func removeFromOperations(_ value: Operation)

    @objc(addOperations:)
    @NSManaged nonisolated public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged nonisolated public func removeFromOperations(_ values: NSSet)

}

// MARK: Generated accessors for sourceReimbursements
extension Vault {

    @objc(addSourceReimbursementsObject:)
    @NSManaged nonisolated public func addToSourceReimbursements(_ value: Reimbursement)

    @objc(removeSourceReimbursementsObject:)
    @NSManaged nonisolated public func removeFromSourceReimbursements(_ value: Reimbursement)

    @objc(addSourceReimbursements:)
    @NSManaged nonisolated public func addToSourceReimbursements(_ values: NSSet)

    @objc(removeSourceReimbursements:)
    @NSManaged nonisolated public func removeFromSourceReimbursements(_ values: NSSet)

}

// MARK: Generated accessors for scheduledOperations
extension Vault {

    @objc(addScheduledOperationsObject:)
    @NSManaged nonisolated public func addToScheduledOperations(_ value: ScheduledOperation)

    @objc(removeScheduledOperationsObject:)
    @NSManaged nonisolated public func removeFromScheduledOperations(_ value: ScheduledOperation)

    @objc(addScheduledOperations:)
    @NSManaged nonisolated public func addToScheduledOperations(_ values: NSSet)

    @objc(removeScheduledOperations:)
    @NSManaged nonisolated public func removeFromScheduledOperations(_ values: NSSet)

}

extension Vault : Identifiable {

}
