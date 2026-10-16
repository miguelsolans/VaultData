//
//  Dashboard+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias DashboardCoreDataPropertiesSet = NSSet

extension Dashboard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dashboard> {
        return NSFetchRequest<Dashboard>(entityName: "Dashboard")
    }

    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var vault: Vault?
    @NSManaged nonisolated public var widgets: NSSet?

}

// MARK: Generated accessors for widgets
extension Dashboard {

    @objc(addWidgetsObject:)
    @NSManaged nonisolated public func addToWidgets(_ value: DashboardWidget)

    @objc(removeWidgetsObject:)
    @NSManaged nonisolated public func removeFromWidgets(_ value: DashboardWidget)

    @objc(addWidgets:)
    @NSManaged nonisolated public func addToWidgets(_ values: NSSet)

    @objc(removeWidgets:)
    @NSManaged nonisolated public func removeFromWidgets(_ values: NSSet)

}

extension Dashboard : Identifiable {

}
