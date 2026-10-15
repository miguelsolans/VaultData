//
//  CategoryRepository.swift
//  Vault
//
//  Created by Miguel Solans on 10/04/2026.
//

import CoreData

public enum ListOrdering {
    case ascending, descending, type
}

public enum ArchiveFilter {
    case any
    case active
    case archived
}

public final class CategoryRepository: CoreDataRepository {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    
    /// Create a new `Category` with provided parameters
    ///
    /// - Parameters
    ///   - `name`: the name chosen name for the category
    ///   - `emoji`: An unicode emoji for the category
    ///   - `color`: the hex color code to represent the category
    ///   - `type`: the type of operation associated with the category
    ///   - `vaultID` the vault where category should be assotiated with
    ///   - `visibleInPlot`: flag indicating whether the category should appear in plotting
    ///
    /// - Returns: The newly created `Category` instance.
    ///
    /// - Throws: An error if:
    ///    - The category creation or persistence process fails.
    @discardableResult
    public func create(
        name: String,
        emoji: String? = nil,
        color: String,
        type: OperationType,
        vaultID: UUID,
        visibleInPlot: Bool,
        budgetRole: BudgetRole = .unclassified
    ) throws -> Category {
        let vaultRequest: NSFetchRequest<Vault> = Vault.fetchRequest()
        vaultRequest.fetchLimit = 1
        vaultRequest.predicate = NSPredicate(format: "id == %@", vaultID as CVarArg)

        guard let vault = try fetchFirst(vaultRequest) else {
            throw RepositoryError.vaultNotFound(vaultID)
        }

        let category = Category(context: context)
        category.id = UUID()
        category.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        category.emoji = emoji
        category.color = color
        category.vault = vault
        category.operationType = type
        category.visibleInPlot = visibleInPlot
        category.budgetRoleType = budgetRole

        try save()
        return category
    }
    
    public func findOrCreate(
        named name: String,
        type: OperationType,
        in vault: Vault,
        color: String,
        visibleInPlot: Bool = true
    ) throws -> Category {
        
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines);
        
        if let existingCategory = try get(name: normalizedName, type: type, in: vault) {
            return existingCategory
        }
        
        return try create(
            name: name,
            color: color,
            type: type,
            vaultID: vault.id!,
            visibleInPlot: visibleInPlot
        )
    }
    
    // MARK: - Read
    
    /// Check if exists at least one `Category` in memory
    ///
    /// - Returns: True if condition is met, false otherwise.
    ///
    /// - Throws: An error if the fetch request fails to execute.
    public func hasAny() throws -> Bool {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.fetchLimit = 1
        return try count(request) > 0
    }
    
    /// Retrieves a list of all `Category` in associated with a `Vault`.
    /// Optionally one or more parameters can be included in the filter,
    /// such as operation type and category name
    ///
    /// - Parameter vault: the vault to look-up categories of
    ///     - `vault`: the vault to look-up categories of
    ///     - `operationType` the type of the operation
    ///     - `name`: the name of the category
    ///
    /// - Returns: A list of `Vault`
    ///
    /// - Throws: An error if the fetch request fails to execute.
    public func getAll(
        from vault: Vault,
        operationType: OperationType? = nil,
        name: String? = nil,
        order: ListOrdering = .ascending,
        archiveFilter: ArchiveFilter = .any
    ) throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        let vaultPredicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Category.vault),
            vault
        )
        
        predicates.append(vaultPredicate)
        
        if let operationType {
            let predicate = NSPredicate(
                format: "%K == %d",
                #keyPath(Operation.type),
                Int(operationType.rawValue)
            )
            
            predicates.append(predicate)
        }
        
        if let name {
            let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let predicate = NSPredicate(
                format: "%K ==[c] %@",
                #keyPath(Category.name),
                normalizedName
            )
            
            predicates.append(predicate)
        }
        
        switch archiveFilter {
        case .any:
            break

        case .active:
            let predicate = NSPredicate(
                format: "%K == false",
                #keyPath(Category.archived)
            )
            
            predicates.append(predicate)

        case .archived:
            let predicate = NSPredicate(
                format: "%K == true",
                #keyPath(Category.archived)
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: predicates
        )
        
        var sortDescriptors: [NSSortDescriptor] = []
        
        switch order {
        case .ascending:
            sortDescriptors.append(.init(key: #keyPath(Category.name), ascending: true))
        case .descending:
            sortDescriptors.append(.init(key: #keyPath(Category.name), ascending: false))
        case .type:
            sortDescriptors.append(.init(key: #keyPath(Category.type), ascending: true))
            sortDescriptors.append(.init(key: #keyPath(Category.name), ascending: true))
        }
        
        request.sortDescriptors = sortDescriptors
        
        return try fetchAll(request)
    }
    
    /// Retrieves a `Category` matching the specified parameters
    ///
    /// - Parameters
    ///     - `id`: the corresponding category id
    ///     - `name`: the name of the category
    ///     - `type`: the operation type associated with the category
    ///     - `vault`: the vault where to look the category in
    ///
    /// - Returns: the `Category` instance with the matching `id`, or `nil` if no such category exists.
    ///
    /// - Throws: An error if the fetch request fails to execute.
    public func get(
        by id: UUID? = nil,
        name: String? = nil,
        type: OperationType? = nil,
        in vault: Vault? = nil
    ) throws -> Category? {
        
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.fetchLimit = 1
        
        var predicates: [NSPredicate] = []
        
        if let id {
            let predicate = NSPredicate(
                format: "id == %@",
                id as CVarArg
            )
            
            predicates.append(predicate)
        }
        
        if let vault {
            let predicate = NSPredicate(
                format: "%K == %@",
                #keyPath(Category.vault),
                vault
            )
            
            predicates.append(predicate)
        }
        
        if let name {
            let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let predicate = NSPredicate(
                format: "%K ==[c] %@",
                #keyPath(Category.name),
                normalizedName
            )
            
            predicates.append(predicate)
        }
        
        if let type {
            let predicate = NSPredicate(
                format: "%K == %d",
                #keyPath(Category.type),
                Int(type.rawValue)
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates);
        
        return try fetchFirst(request)
    }
    
    // MARK: - Update
    
    /// Updates the given `Category` with the provided values
    ///
    /// - Parameters
    ///     - `category`: The `Category` instance to update
    ///     - `newName`: The name chosen to the category
    ///     - `newEmoji`: An unicode emoji for the category
    ///     - `newColor`: The hex color code to represent the category
    ///     - `newType`: The type of the operation
    ///     - `newVisibleInPlot`: A flag indicating whether the category should appear in plotting
    ///
    ///  - Throws: An error if update request fails to execute
    public func update(
        _ category: Category,
        newName: String? = nil,
        newEmoji: String? = nil,
        newColor: String? = nil,
        newType: OperationType? = nil,
        newVisibleInPlot: Bool? = nil,
        newBudget: NSDecimalNumber? = nil,
        newBudgetRole: BudgetRole? = nil,
        newArchived: Bool? = nil
    ) throws {
        
        if let newName {
            category.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let newEmoji {
            category.emoji = newEmoji
        }
        
        if let newColor {
            category.color = newColor
        }

        if let newType {
            category.operationType = newType
        }

        if let newVisibleInPlot {
            category.visibleInPlot = newVisibleInPlot
        }
        
        if let newBudgetRole {
            category.budgetRoleType = newBudgetRole
        }
        
        if let newArchived {
            category.archived = newArchived
        }
        
        category.hasMonthlyBudget = newBudget != nil
        
        category.monthlyBudget = newBudget
        
        try save()
    }
    
    
    // MARK: - Delete

    /// Deletes the specificied `Category`
    ///
    /// - Parameter category: The `category` instance to be deleted
    ///
    /// - Throws: An error if saving context fails
    ///
    /// - Important: After deletion, the provided `Category` instance should no longer be used, as it becomes invalid once removed from the context.
    public func delete(_ category: Category) throws {
        context.delete(category)
        try save()
    }

    /// Deletes all data from `Category`
    ///
    /// - Throws: An error if saving context fails
    ///
    /// - Important: After deletion, all information regarind any `Category` instance should no longer be used, as it becomes invalid once removed from the context.
    public func deleteAll(from vault: Vault) throws {
        let categories = try getAll(from: vault)
        categories.forEach(context.delete)
        try save()
    }
}
