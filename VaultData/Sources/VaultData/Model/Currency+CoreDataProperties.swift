//
//  Currency+CoreDataProperties.swift
//  Vault
//
//  Created by Miguel Solans on 30/09/2026.
//
//

public import Foundation
public import CoreData


public typealias CurrencyCoreDataPropertiesSet = NSSet

extension Currency {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Currency> {
        return NSFetchRequest<Currency>(entityName: "Currency")
    }

    @NSManaged nonisolated public var code: String?
    @NSManaged nonisolated public var id: UUID?
    @NSManaged nonisolated public var name: String?
    @NSManaged nonisolated public var symbol: String?
    @NSManaged nonisolated public var vaults: NSSet?

}

// MARK: Generated accessors for vaults
extension Currency {

    @objc(addVaultsObject:)
    @NSManaged nonisolated public func addToVaults(_ value: Vault)

    @objc(removeVaultsObject:)
    @NSManaged nonisolated public func removeFromVaults(_ value: Vault)

    @objc(addVaults:)
    @NSManaged nonisolated public func addToVaults(_ values: NSSet)

    @objc(removeVaults:)
    @NSManaged nonisolated public func removeFromVaults(_ values: NSSet)

}

extension Currency : Identifiable {

}
