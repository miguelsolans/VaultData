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
        notes: String? = nil,
        date: Date,
        type: OperationType,
        amount: Decimal,
        vault: VaultEntity,
        category: CategoryEntity,
        reimbursementSource: ReimbursementEntity? = nil,
        splittingType: SplittingType = .none
    ) throws -> OperationEntity {
        
        let operation = OperationEntity(context: context)
        let now = Date()
        
        operation.id = UUID()
        operation.createdAt = now
        operation.updatedAt = now
        operation.title = title
        operation.notes = notes
        operation.date = date
        operation.operationType = type
        operation.amountDecimal = NSDecimalNumber(decimal: amount)
        operation.vault = vault
        operation.category = category
        operation.reimbursementSource = reimbursementSource
        operation.splittingType = splittingType

        try save()
        return operation
    }
    
    // MARK: - Read
    
    public func count(
        in vault: VaultEntity,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        type operationType: OperationType? = nil
    ) throws -> Int {
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        let vaultPredicate = NSPredicate(
            format: "%K == %@",
            #keyPath(OperationEntity.vault),
            vault
        )
        
        predicates.append(vaultPredicate)
        
        if let startDate {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(OperationEntity.date),
                startDate as NSDate
            )
            
            predicates.append(predicate)
        }
        
        if let endDate {
            let predicate = NSPredicate(
                format: "%K <= %@",
                #keyPath(OperationEntity.date),
                endDate as NSDate
            )
            
            predicates.append(predicate)
        }
        
        if let operationType {
            let predicate = NSPredicate(
                format: "%K == %d",
                #keyPath(OperationEntity.type),
                Int(operationType.rawValue)
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.fetchLimit = 1
        return try count(request)
    }
    
    /// Retrieves a list of all `Operation` in memory
    ///
    /// - Parameter vault: Vault where to fetch the operations
    ///
    /// - Returns: A list of `Operation`
    ///
    /// - Throws: An error if:
    ///    - Fetch operation fails
    public func getAll(
        from vault: VaultEntity
    ) throws -> [OperationEntity] {
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(OperationEntity.vault),
            vault
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\OperationEntity.date, order: .forward)),
            
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
    public func getAll(
        from vault: VaultEntity,
        year: Int
    ) throws -> [OperationEntity] {
        
        let calendar = Calendar.current

        guard
            let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
            let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        else {
            throw GeneralError.invalidYear(year)
        }

        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K >= %@ AND %K < %@",
            #keyPath(OperationEntity.vault),
            vault,
            #keyPath(OperationEntity.date),
            startOfYear as NSDate,
            #keyPath(OperationEntity.date),
            endOfYear as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\OperationEntity.date, order: .forward))
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
        from vault: VaultEntity,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        operationType: OperationType? = nil,
        reimbursementStatus: ReimbursementStatus? = nil
    ) throws -> [OperationEntity] {
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(OperationEntity.vault),
                vault
            )
        )
        
        if let startDate {
            predicates.append(
                NSPredicate(
                    format: "%K >= %@",
                    #keyPath(OperationEntity.date),
                    startDate as NSDate
                )
            )
        }
        
        if let endDate {
            predicates.append(
                NSPredicate(
                    format: "%K <= %@",
                    #keyPath(OperationEntity.date),
                    endDate as NSDate
                )
            )
        }
        
        if let operationType {
            predicates.append(
                NSPredicate(
                    format: "%K == %d",
                    #keyPath(OperationEntity.type),
                    Int(operationType.rawValue)
                )
            )
        }
        
        if let reimbursementStatus {
            predicates.append(
                NSPredicate(
                    format: "ANY %K.%K == %d",
                    #keyPath(OperationEntity.reimbursements),
                    #keyPath(ReimbursementEntity.status),
                    Int(reimbursementStatus.rawValue)
                )
            )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = [
            NSSortDescriptor(
                SortDescriptor(\OperationEntity.date, order: .forward)
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
    public func get(
        by id: UUID
    ) throws -> OperationEntity? {
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
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
        _ operation: OperationEntity,
        newTitle: String? = nil,
        newNotes: String?? = nil,
        newDate: Date?? = nil,
        newType: OperationType? = nil,
        newAmount: Decimal? = nil,
        newCategoryID: UUID?? = nil
    ) throws {
        if let newTitle {
            operation.title = newTitle
        }

        if let newNotes {
            operation.notes = newNotes
        }

        if let newDate {
            operation.date = newDate
        }

        if let newType {
            operation.operationType = newType
        }

        if let newAmount {
            operation.amountDecimal = NSDecimalNumber(decimal: newAmount)
        }

        if let newCategoryID {
            if let categoryID = newCategoryID {
                let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
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
    public func delete(_ operation: OperationEntity) throws {
        context.delete(operation)
        try save()
    }

    /// Deletes all operations in a specified `Vault`
    ///
    /// - Throws: an error if saving context fails
    ///
    /// - Important: After deletion, all information regarding any `Operation` in the specific `Vault` instance should no longer be used, as it becomes invalid once removed from the context.
    public func deleteAll(in vault: VaultEntity) throws {
        let operations = try getAll(from: vault)
        operations.forEach(context.delete)
        try save()
    }
}

extension OperationRepository {
    public func getOperationsMatching(
        title: String?,
        between minAmount: NSDecimalNumber?,
        and maxAmount: NSDecimalNumber?,
        with categoryNames: [String]?,
        of type: OperationType?, in
        vault: [String]?
    ) throws -> [OperationEntity] {
        
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let title {
            let predicate = NSPredicate(
                format: "%K CONTAINS[c] %@",
                #keyPath(OperationEntity.title),
                title
            )
            
            predicates.append(predicate)
        }
        
        if let minAmount {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(OperationEntity.amountDecimal),
                minAmount
            )
            
            predicates.append(predicate)
        }
        
        if let maxAmount {
            let predicate = NSPredicate(
                format: "%K >= %@",
                #keyPath(OperationEntity.amountDecimal),
                maxAmount
            )
            
            predicates.append(predicate)
        }
        
        if let vault {
            let predicate = NSPredicate(
                format: "%K IN %@",
                #keyPath(OperationEntity.vault.title),
                vault
            )
            
            predicates.append(predicate)
        }
        
        if let type {
            let predicate = NSPredicate(
                format: "%K == %d",
                #keyPath(OperationEntity.type),
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
        for scheduledOperation: ScheduledOperationEntity,
        on occurrenceDate: Date
    ) throws -> OperationEntity? {
        let request: NSFetchRequest<OperationEntity> = OperationEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(OperationEntity.scheduledOperation),
            scheduledOperation,
            #keyPath(OperationEntity.scheduledDate),
            occurrenceDate as NSDate
        )
        return try fetchFirst(request)
    }
}
