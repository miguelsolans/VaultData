//
//  VaultRepository.swift
//  Vault
//
//  Created by Miguel Solans on 10/04/2026.
//

import CoreData
import VaultDomain

public final class VaultRepository: CoreDataRepository {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    /// Create a new `Vault` with provided parameters
    ///
    /// - Parameters
    ///   - `title`: the name chosen name for the Vault
    ///   - `initialDeposit`: starting balance of the Vault. Does not create operation for tracking history
    ///
    /// - Returns: The newly created `Vault` instance.
    ///
    /// - Throws: An error if:
    ///    - The vault creation or persistence process fails.
    @discardableResult
    public func create(
        with title: String,
        initialDeposit: Decimal
    ) throws -> VaultEntity {

        let vault = VaultEntity(context: context)
        vault.id = UUID()
        vault.title = title
        vault.initialAmountDecimal = NSDecimalNumber(decimal: initialDeposit)

        try save()
        return vault
    }
    
    // MARK: - Read
    
    public func count() throws -> Int {
        let request: NSFetchRequest<VaultEntity> = VaultEntity.fetchRequest()
        request.fetchLimit = 1
        return try count(request)
    }
    
    /// Retrieves a list of all `Vault` in memory
    ///
    /// - Returns: A list of `Vault`
    public func getAll() throws -> [VaultEntity] {
        let request: NSFetchRequest<VaultEntity> = VaultEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\VaultEntity.title, order: .forward))
        ]
        return try fetchAll(request)
    }
    
    /// Retrieves a `Vault` matching the specified identifier.
    ///
    /// - Parameter id: The unique identifier of the vault to retrieve.
    ///
    /// - Returns: The `Vault` instance with the matching `id`, or `nil` if no such vault exists.
    ///
    /// - Throws: An error if the fetch request fails to execute.
    public func get(
        by id: UUID
    ) throws -> VaultEntity? {
        let request: NSFetchRequest<VaultEntity> = VaultEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try fetchFirst(request)
    }
    
    /// Retrieves a `Vault` matching title
    ///
    /// - Parameter name: The title of the vault to retrieve.
    ///
    /// - Returns: The `Vault` instance with the matching `title`, or `nil` if no such vault exists.
    ///
    /// - Throws: An error if the fetch request fails to execute.
    public func get(
        by name: String
    ) throws -> VaultEntity? {
        let request: NSFetchRequest<VaultEntity> = VaultEntity.fetchRequest()
        
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "title ==[c] %@", name)
        
        return try fetchFirst(request)
    }
    
    // MARK: - Update
    
    /// Updates the given `Vault` with the provided values.
    ///
    /// - Parameters:
    ///     - `vault`: The `Vault` instance to update.
    ///     - `newTitle`: An optional new title for the vault.
    ///     - `initialDeposit`: An optional new initial deposit amount.
    ///
    /// - Throws: An error if:
    ///     - Saving the updated vault fails.
    public func update(
        _ vault: VaultEntity,
        newTitle: String? = nil,
        initialDeposit: Decimal? = nil,
    ) throws {
        if let newTitle {
            vault.title = newTitle
        }

        if let initialDeposit {
            vault.initialAmountDecimal = NSDecimalNumber(decimal: initialDeposit)
        }

        try save()
    }
    
    public func setMainIncome(_ vault: VaultEntity, category: CategoryEntity) throws {
        vault.mainIncomeCategory = category
        
        try save()
    }
    
    public func clearMainIncome(_ vault: VaultEntity) throws {
        vault.mainIncomeCategory = nil
        
        try save()
    }
    
    // MARK: Delete
    
    /// Deletes the specified `Vault`
    ///
    /// - Parameter vault: the `Vault` instance to be deleted
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, the provided `Vault` instance should no longer be used, as it becomes invalid once removed from the context.
    public func delete(
        _ vault: VaultEntity
    ) throws {
        context.delete(vault)
        try save()
    }
    
    /// Deletes all data from `Vault`
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, all information regarding any `Vault` instance should no longer be used, as it becomes invalid once removed from the context.
    public func deleteAll() throws {
        let request: NSFetchRequest<VaultEntity> = VaultEntity.fetchRequest()
        let vaults = try context.fetch(request)
        vaults.forEach(context.delete)
        try save()
    }
}
