//
//  Settings+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias SettingsCoreDataPropertiesSet = NSSet

extension Settings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }

    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var lastOpened: Date?
    @NSManaged nonisolated public var favoriteVault: Vault?

}

extension Settings : Identifiable {

}
