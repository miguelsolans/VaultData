//
//  DashboardWidget+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias DashboardWidgetCoreDataPropertiesSet = NSSet

extension DashboardWidget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DashboardWidget> {
        return NSFetchRequest<DashboardWidget>(entityName: "DashboardWidget")
    }

    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var isVisible: Bool
    @NSManaged nonisolated public var sortOrder: Int16
    @NSManaged nonisolated public var type: Int16
    @NSManaged nonisolated public var dashboard: Dashboard?

}

extension DashboardWidget : Identifiable {

}
