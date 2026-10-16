//
//  OperationRepository.swift
//  Vault
//
//  Created by Miguel Solans on 10/04/2026.
//

import CoreData
import VaultDomain

public final class OperationRepository: CoreDataRepository {
    
    public let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Creat
    
    /// Create a new `Operation` with provided parameters
    ///
    /// - Parameters
    ///   - `title`: The chosen title for the operation
    ///   - `subtitle`: The chosen subtitle for the operation
    ///   - `date`: The date when the operation took place
    ///   - `type`: The type of the operation
    ///   - `amount`: The amount ot the operation
    ///   - `vaultID` The vault identifier where the operation should be added
    ///   - `categoryID`The category identifier to classify the operation
    ///
    /// - Returns: The newly created `Vault` instance.
    ///
    /// - Throws: An error if:
    ///    - The operation creation or persistence process fails.
    @discardableResult
    public func add(
        title: String,
        subtitle: String? = nil,
        date: Date,
        type: OperationType,
        amount: Double,
        vault: Vault,
        category: Category,
        reimbursementSource: Reimbursement? = nil,
        splittingType: SplittingType = .none
    ) throws -> Operation {
        
        let operation = Operation(context: context)
        let now = Date()
        
        operation.id = UUID()
        operation.createdAt = now
        operation.updatedAt = now
        operation.title = title
        operation.subtitle = subtitle
        operation.date = date
        operation.operationType = type
        operation.amount = amount
        operation.vault = vault
        operation.category = category
        operation.reimbursementSource = reimbursementSource
        operation.splittingType = splittingType

        try save()
        return operation
    }
    
    // MARK: - Read
    
    /// Check if exists any`Operation` matching a range of dates
    ///
    /// - Returns: True if condition is met, false otherwise.
    public func hasAny(in vault: Vault, between startDate: Date? = nil, and endDate: Date? = nil) throws -> Bool {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        let vaultPredicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Operation.vault),
            vault
        )
        
        predicates.append(vaultPredicate)
        
        if let startDate {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(Operation.date),
                startDate as NSDate
            )
            
            predicates.append(predicate)
        }
        
        if let endDate {
            let predicate = NSPredicate(
                format: "%K <= %@",
                #keyPath(Operation.date),
                endDate as NSDate
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.fetchLimit = 1
        return try count(request) > 0
    }
    
    /// Retrieves a list of all `Operation` in memory
    ///
    /// - Parameter vault: Vault where to fetch the operations
    ///
    /// - Returns: A list of `Operation`
    ///
    /// - Throws: An error if:
    ///    - Fetch operation fails
    public func getAll(from vault: Vault) throws -> [Operation] {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Operation.vault),
            vault
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\Operation.date, order: .forward)),
            
        ]
        return try fetchAll(request)
    }

    /// Retrieves a list of all `Operations` created within a given year
    ///
    /// - Parameters
    ///     - `vault`: The vault where to look the operations
    ///     - `year`: The year of the operation creation date
    ///
    /// - Returns: A list of `Operation`
    ///
    /// - Throws: An error if:
    ///     - Fetch operation fails
    public func getAll(from vault: Vault, year: Int) throws -> [Operation] {
        guard (1...9999).contains(year) else {
            throw GeneralError.invalidYear(year)
        }

        let calendar = Calendar.current

        guard
            let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
            let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            throw GeneralError.invalidYear(year)
        }

        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@ AND %K < %@",
            #keyPath(Operation.vault),
            vault,
            #keyPath(Operation.date),
            startOfYear as NSDate,
            #keyPath(Operation.date),
            endOfYear as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\Operation.date, order: .forward))
        ]

        return try fetchAll(request)
    }
    
    /// Retrieves a list of all `Operations` created between two given datesr
    ///
    /// - Parameters
    ///     - `vault`: The vault where to look the operations
    ///     - `startDate`: The start date filter to look-up
    ///     - `endDate`: The end date filter to look-up
    ///
    /// - Returns: A list of `Operation`
    ///
    /// - Throws: An error if:
    ///     - Fetch operation fails
    public func getAll(
        from vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        operationType: OperationType? = nil,
        reimbursementStatus: ReimbursementStatus? = nil
    ) throws -> [Operation] {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(Operation.vault),
                vault
            )
        )
        
        if let startDate {
            predicates.append(
                NSPredicate(
                    format: "%K >= %@",
                    #keyPath(Operation.date),
                    startDate as NSDate
                )
            )
        }
        
        if let endDate {
            predicates.append(
                NSPredicate(
                    format: "%K <= %@",
                    #keyPath(Operation.date),
                    endDate as NSDate
                )
            )
        }
        
        if let operationType {
            predicates.append(
                NSPredicate(
                    format: "%K == %d",
                    #keyPath(Operation.type),
                    Int(operationType.rawValue)
                )
            )
        }
        
        if let reimbursementStatus {
            predicates.append(
                NSPredicate(
                    format: "ANY %K.%K == %d",
                    #keyPath(Operation.reimbursements),
                    #keyPath(Reimbursement.status),
                    Int(reimbursementStatus.rawValue)
                )
            )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = [
            NSSortDescriptor(
                SortDescriptor(\Operation.date, order: .forward)
            )
        ]
        
        return try fetchAll(request)
    }

    /// Fetches a single operation with a given identifer
    ///
    /// - Parameters
    ///     - `id`: The identifier of the operation
    ///
    /// - Returns: The `Operation` instance with the matching `id`, or `nil` if no such operation exists
    ///
    /// - Throws: An error if:
    ///     - Fetch operation fails
    public func get(by id: UUID) throws -> Operation? {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try fetchFirst(request)
    }
    
    // MARK: - Update
    
    /// Updates the given `Operation` with the provided values.
    ///
    /// - Parameters:
    ///     - `operation`: The `Operation` instance to update.
    ///     - `newTitle`: An optional new title for the operation.
    ///     - `newSubtitle`: An optional new subtitle for the operation.
    ///     - `newDate`: An optional new date for the operation.
    ///     - `newType`: An optional new operation type for the operation.
    ///     - `newAmount`: An optional new amount type for the operation.
    ///     - `newCategoryID`: An optional new category ID for the operation.
    ///
    /// - Throws: An error if:
    ///     - Saving the updated operation fails.
    public func update(
        _ operation: Operation,
        newTitle: String? = nil,
        newSubtitle: String?? = nil,
        newDate: Date?? = nil,
        newType: OperationType? = nil,
        newAmount: Double? = nil,
        newCategoryID: UUID?? = nil
    ) throws {
        if let newTitle {
            operation.title = newTitle
        }

        if let newSubtitle {
            operation.subtitle = newSubtitle
        }

        if let newDate {
            operation.date = newDate
        }

        if let newType {
            operation.operationType = newType
        }

        if let newAmount {
            operation.amount = newAmount
        }

        if let newCategoryID {
            if let categoryID = newCategoryID {
                let request: NSFetchRequest<Category> = Category.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "id == %@", categoryID as CVarArg)

                guard let category = try fetchFirst(request) else {
                    throw CategoryError.notFound(categoryID)
                }

                operation.category = category
            } else {
                operation.category = nil
            }
        }

        if operation.hasChanges {
            operation.updatedAt = Date()
        }

        try save()
    }
    
    // MARK: - Delete

    /// Deletes the specified `Operation`
    ///
    /// - Parameter opertation: the `Opertaion` instance to be deleted
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, the provided `Operation` instance should no longer be used, as it becomes invalid once removed from the context.
    public func delete(_ operation: Operation) throws {
        context.delete(operation)
        try save()
    }

    /// Deletes all operations in a specified `Vault`
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, all information regarding any `Operation` in the specific `Vault` instance should no longer be used, as it becomes invalid once removed from the context.
    public func deleteAll(in vault: Vault) throws {
        let operations = try getAll(from: vault)
        operations.forEach(context.delete)
        try save()
    }
}

extension OperationRepository {
    public func getOperationsMatching(
        title: String?,
        between minAmount: Double?,
        and maxAmount: Double?,
        with categoryNames: [String]?,
        of type: OperationType?, in
        vault: [String]?
    ) throws -> [Operation] {
        
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let title {
            let predicate = NSPredicate(
                format: "%K CONTAINS[c] %@",
                #keyPath(Operation.title),
                title
            )
            
            predicates.append(predicate)
        }
        
        if let minAmount {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(Operation.amount),
                minAmount
            )
            
            predicates.append(predicate)
        }
        
        if let maxAmount {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(Operation.amount),
                maxAmount
            )
            
            predicates.append(predicate)
        }
        
        if let vault {
            let predicate = NSPredicate(
                format: "%K IN %@",
                #keyPath(Operation.vault.title),
                vault
            )
            
            predicates.append(predicate)
        }
        
        if let type {
            let predicate = NSPredicate(
                format: "%K == %d",
                #keyPath(Operation.type),
                Int(type.rawValue)
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        return try fetchAll(request)
    }
}

// MARK: - Schedule

extension OperationRepository {
    
    public func getScheduledOccurrence(
        for scheduledOperation: ScheduledOperation,
        on occurrenceDate: Date
    ) throws -> Operation? {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(Operation.scheduledOperation),
            scheduledOperation,
            #keyPath(Operation.scheduledDate),
            occurrenceDate as NSDate
        )
        return try fetchFirst(request)
    }
}
