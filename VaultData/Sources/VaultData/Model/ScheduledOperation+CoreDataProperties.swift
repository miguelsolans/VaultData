//
//  ScheduledOperation+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias ScheduledOperationCoreDataPropertiesSet = NSSet

extension ScheduledOperation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScheduledOperation> {
        return NSFetchRequest<ScheduledOperation>(entityName: "ScheduledOperation")
    }

    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var title: String?
    @NSManaged nonisolated public var amount: Double
    @NSManaged nonisolated public var recurrence: Int16
    @NSManaged nonisolated public var startDate: Date?
    @NSManaged nonisolated public var endDate: Date?
    @NSManaged nonisolated public var nextOccurrenceDate: Date?
    @NSManaged nonisolated public var occurrenceCount: Int32
    @NSManaged nonisolated public var isActive: Bool
    @NSManaged nonisolated public var createdAt: Date?
    @NSManaged nonisolated public var updatedAt: Date?
    @NSManaged nonisolated public var vault: Vault?
    @NSManaged nonisolated public var category: Category?
    @NSManaged nonisolated public var operations: NSSet?

}

// MARK: Generated accessors for operations
extension ScheduledOperation {

    @objc(addOperationsObject:)
    @NSManaged nonisolated public func addToOperations(_ value: Operation)

    @objc(removeOperationsObject:)
    @NSManaged nonisolated public func removeFromOperations(_ value: Operation)

    @objc(addOperations:)
    @NSManaged nonisolated public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged nonisolated public func removeFromOperations(_ values: NSSet)

}

extension ScheduledOperation : Identifiable {

}
