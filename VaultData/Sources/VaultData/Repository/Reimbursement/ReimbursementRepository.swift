//
//  ReimbursementRepository.swift
//  Vault
//
//  Created by Miguel Solans on 23/04/2026.
//

import CoreData
import VaultDomain

public final class ReimbursementRepository: CoreDataRepository {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Create

    /// Creates a new `Reimbursement`
    ///
    /// - Parameters:
    ///   - amount: Reimbursement amount
    ///   - operation: The original operation this reimbursement belongs to
    ///   - sourceVault: The vault where the reimbursable money left
    ///   - destinationVault: The vault where the reimbursement will be deposited
    ///   - status: The reimbursement status raw value
    ///   - date: Optional reimbursement date
    ///
    /// - Returns: The newly created `Reimbursement`
    ///
    /// - Throws: An error if validation fails or persistence fails
    @discardableResult
    public func add(
        amount: Decimal,
        operation: OperationEntity,
        sourceVault: VaultEntity,
        destinationVault: VaultEntity,
        status: ReimbursementStatus,
        date: Date? = nil,
        title: String? = nil,
        category: CategoryEntity
    ) throws -> ReimbursementEntity {

        let reimbursement = ReimbursementEntity(context: context)

        reimbursement.id = UUID()
        reimbursement.amount = NSDecimalNumber(decimal: amount)
        reimbursement.originalOperation = operation
        reimbursement.sourceVault = sourceVault
        reimbursement.destinationVault = destinationVault
        reimbursement.status = status.rawValue
        reimbursement.title = title
        reimbursement.destinationCategory = category

        try save()
        return reimbursement
    }

    public func linkIncomeOperation(
        _ incomeOperation: OperationEntity,
        to reimbursement: ReimbursementEntity
    ) throws {
        reimbursement.incomeOperation = incomeOperation
        try save()
    }

    // MARK: - Read

    /// Fetches a single reimbursement by identifier
    ///
    /// - Parameter id: Reimbursement identifier
    ///
    /// - Returns: The matching `Reimbursement`, or nil if not found
    ///
    /// - Throws: An error if fetch fails
    public func get(
        by id: UUID
    ) throws -> ReimbursementEntity? {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try fetchFirst(request)
    }

    /// Fetches all reimbursements for a given operation
    ///
    /// - Parameter operation: The parent operation
    ///
    /// - Returns: A list of reimbursements
    ///
    /// - Throws: An error if fetch fails
    public func getAll(
        for operation: OperationEntity
    ) throws -> [ReimbursementEntity] {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(ReimbursementEntity.originalOperation),
            operation
        )

        return try fetchAll(request)
    }

    /// Fetches all reimbursements deposited in a given vault
    ///
    /// - Parameter vault: The destination vault
    ///
    /// - Returns: A list of reimbursements
    ///
    /// - Throws: An error if fetch fails
    public func getAll(depositedIn vault: VaultEntity) throws -> [ReimbursementEntity] {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(ReimbursementEntity.destinationVault),
            vault
        )

        return try fetchAll(request)
    }

    // MARK: - Update

    /// Updates the given `Reimbursement` with the provided values
    ///
    /// - Parameters:
    ///   - reimbursement: The reimbursement to update
    ///   - newAmount: Optional new amount
    ///   - newDestinationVault: Optional new destination vault
    ///   - newStatus: Optional new status raw value
    ///   - newDate: Optional new date
    ///
    /// - Throws: An error if validation or persistence fails
    public func update(
        _ reimbursement: ReimbursementEntity,
        newAmount: Decimal? = nil,
        newDestinationVault: VaultEntity? = nil,
        newStatus: ReimbursementStatus? = nil,
        newDate: Date?? = nil,
        newTitle: String? = nil,
        newCategory: CategoryEntity? = nil
    ) throws {
        
        if let newAmount {
            reimbursement.amount = NSDecimalNumber(decimal: newAmount)
        }

        if let newDestinationVault {
            reimbursement.destinationVault = newDestinationVault
        }

        if let newStatus {
            reimbursement.status = newStatus.rawValue
        }
        
        if let newTitle {
            reimbursement.title = newTitle
        }
        
        if let newCategory {
            reimbursement.destinationCategory = newCategory
        }
        
        try save()
    }

    // MARK: - Delete

    /// Deletes the specified reimbursement
    ///
    /// - Parameter reimbursement: The reimbursement to delete
    ///
    /// - Throws: An error if saving context fails
    public func delete(_ reimbursement: ReimbursementEntity) throws {
        context.delete(reimbursement)
        try save()
    }

    /// Deletes all reimbursements associated with an operation
    ///
    /// - Parameter operation: The parent operation
    ///
    /// - Throws: An error if saving context fails
    public func deleteAll(for operation: OperationEntity) throws {
        let reimbursements = try getAll(for: operation)
        reimbursements.forEach(context.delete)
        try save()
    }
    
    public func deleteAll() throws {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        let reimbursements = try context.fetch(request)
        reimbursements.forEach(context.delete)
        try save()
    }
}

// MARK: - Metrics
extension ReimbursementRepository {
    
    public func total(
        in vault: VaultEntity,
        with status: ReimbursementStatus,
        sameVault: Bool,
        between startDate: Date? = nil,
        and endDate: Date? = nil
    ) throws -> Decimal {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(
                    forKeyPath: #keyPath(ReimbursementEntity.amount)
                )
            ]
        )
        
        expression.expressionResultType = .decimalAttributeType
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(ReimbursementEntity.sourceVault),
                vault
            )
        )
        
        if sameVault {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    #keyPath(ReimbursementEntity.destinationVault),
                    vault
                )
            )
        }
        
        if !sameVault {
            predicates.append(
                NSPredicate(
                    format: "%K != %@",
                    #keyPath(ReimbursementEntity.destinationVault),
                    vault
                )
            )
        }
        
        predicates.append(
            NSPredicate(
                format: "%K == %d",
                #keyPath(ReimbursementEntity.status),
                Int(status.rawValue)
            )
        )

        if let startDate {
            predicates.append(
                NSPredicate(
                    format: "%K >= %@",
                    #keyPath(ReimbursementEntity.originalOperation.date),
                    startDate as NSDate
                )
            )
        }

        if let endDate {
            predicates.append(
                NSPredicate(
                    format: "%K <= %@",
                    #keyPath(ReimbursementEntity.originalOperation.date),
                    endDate as NSDate
                )
            )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Decimal ?? .zero
        
        return total
    }
    
    public func total(
        for operation: OperationEntity
    ) throws -> Decimal? {
        let request: NSFetchRequest<ReimbursementEntity> = ReimbursementEntity.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(
                    forKeyPath: #keyPath(ReimbursementEntity.amount)
                )
            ]
        )
        
        expression.expressionResultType = .decimalAttributeType
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(ReimbursementEntity.originalOperation),
                operation
            )
        )
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Decimal
        
        return total
    }
}
