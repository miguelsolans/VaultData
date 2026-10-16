//
//  CurrencyRepository.swift
//  Vault
//
//  Created by Miguel Solans on 10/04/2026.
//

import CoreData

public final class CurrencyRepository: CoreDataRepository {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    /// Create a new `Currency` with provided parameters
    ///
    /// - Parameters
    ///     - `code`:  the ISO 4217 currency code
    ///     - `name`: the name of the currency
    ///     - `symbol`: the corresponding symbol of the currency
    ///
    /// - Throws: An error if the fetch request fails to execute
    @discardableResult
    public func create(
        code: String,
        name: String,
        symbol: String
    ) throws -> Currency {
        let currency = Currency(context: context)
        currency.id = UUID()
        currency.code = code
        currency.name = name
        currency.symbol = symbol

        try save()
        return currency
    }
    
    // MARK: - Read
    
    /// Check if exists at least one `Vault` in memory
    ///
    /// - Returns: True if condition is met, false otherwise.
    ///
    /// - Throws: An error if the fetch request fails to execute
    public func hasAny() throws -> Bool {
        let request: NSFetchRequest<Currency> = Currency.fetchRequest()
        request.fetchLimit = 1
        return try count(request) > 0
    }
    
    /// Retrieves a list of all `Currency` in memory
    ///
    /// - Returns: a list of `Currency`
    ///
    /// - Throws: An error if the fetch request fails to execute
    public func getAll() throws -> [Currency] {
        let request: NSFetchRequest<Currency> = Currency.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\Currency.code, order: .forward))
        ]
        return try fetchAll(request)
    }
    
    /// Retrieves a `Currency` matching the specified currency code
    ///
    /// - Returns: The `Currency` instance matching the `code`, or `nil` if no such currency exists.
    ///
    /// - Throws: An error if the fetch request fails to execute
    public func get(byCode code: String) throws -> Currency? {
        let request: NSFetchRequest<Currency> = Currency.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Currency.code),
            code
        )
        return try fetchFirst(request)
    }
    
    /// Retrieves a `Currency` matching the specified id
    ///
    /// - Returns: The `Currency` instance matching the `id`, or `nil` if no such currency exists.
    ///
    /// - Throws: An error if the fetch request fails to execute
    public func get(byID id: UUID) throws -> Currency? {
        let request: NSFetchRequest<Currency> = Currency.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Currency.code),
            id as CVarArg
        )
        return try fetchFirst(request)
    }
}
