//
//  VaultRepository.swift
//  Vault
//
//  Created by Miguel Solans on 10/04/2026.
//

import CoreData

public final class VaultRepository: CoreDataRepository {
    let context: NSManagedObjectContext
    private let currencyRepository: CurrencyRepository

    init(context: NSManagedObjectContext) {
        self.context = context
        self.currencyRepository = CurrencyRepository(context: context)
    }
    
    // MARK: - Create
    
    /// Create a new `Vault` with provided parameters
    ///
    /// - Parameters
    ///   - `title`: the name chosen name for the Vault
    ///   - `initialDeposit`: starting balance of the Vault. Does not create operation for tracking history
    ///   - `currencyCode`: the ISO 4217 currency code representing the Vault currency
    ///
    /// - Returns: The newly created `Vault` instance.
    ///
    /// - Throws: An error if:
    ///    - The vault creation or persistence process fails.
    @discardableResult
    public func create(
        with title: String,
        initialDeposit: Double,
        currencyCode: String
    ) throws -> Vault {
        guard let currency = try currencyRepository.get(byCode: currencyCode) else {
            throw RepositoryError.currencyNotFound(currencyCode)
        }

        let vault = Vault(context: context)
        vault.id = UUID()
        vault.title = title
        vault.initialDeposit = initialDeposit
        vault.currencyRelation = currency

        try save()
        return vault
    }
    
    // MARK: - Read
    
    /// Check if exists at least one `Vault` in memory
    ///
    /// - Returns: True if condition is met, false otherwise.
    public func hasAny() throws -> Bool {
        let request: NSFetchRequest<Vault> = Vault.fetchRequest()
        request.fetchLimit = 1
        return try count(request) > 0
    }
    
    /// Retrieves a list of all `Vault` in memory
    ///
    /// - Returns: A list of `Vault`
    public func getAll() throws -> [Vault] {
        let request: NSFetchRequest<Vault> = Vault.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\Vault.title, order: .forward))
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
    public func get(by id: UUID) throws -> Vault? {
        let request: NSFetchRequest<Vault> = Vault.fetchRequest()
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
    public func get(by name: String) throws -> Vault? {
        let request: NSFetchRequest<Vault> = Vault.fetchRequest()
        
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
    ///     - `currencyCode`: An optional ISO 4217 currency code
    ///
    /// - Throws: An error if:
    ///     - The provided `currencyCode` does not correspond to an existing currency.
    ///     - Saving the updated vault fails.
    public func update(
        _ vault: Vault,
        newTitle: String? = nil,
        initialDeposit: Double? = nil,
        currencyCode: String? = nil
    ) throws {
        if let newTitle {
            vault.title = newTitle
        }

        if let initialDeposit {
            vault.initialDeposit = initialDeposit
        }

        if let currencyCode {
            guard let currency = try currencyRepository.get(byCode: currencyCode) else {
                throw RepositoryError.currencyNotFound(currencyCode)
            }
            vault.currencyRelation = currency
        }

        try save()
    }
    
    public func setMainIncome(_ vault: Vault, category: Category) throws {
        vault.mainIncomeCategory = category
        
        try save()
    }
    
    public func clearMainIncome(_ vault: Vault) throws {
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
    public func delete(_ vault: Vault) throws {
        context.delete(vault)
        try save()
    }
    
    /// Deletes all data from `Vault`
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, all information regarding any `Vault` instance should no longer be used, as it becomes invalid once removed from the context.
    public func deleteAll() throws {
        let request: NSFetchRequest<Vault> = Vault.fetchRequest()
        let vaults = try context.fetch(request)
        vaults.forEach(context.delete)
        try save()
    }
}
