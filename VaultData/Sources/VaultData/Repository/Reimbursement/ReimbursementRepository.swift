//
//  ReimbursementRepository.swift
//  Vault
//
//  Created by Miguel Solans on 23/04/2026.
//

import CoreData

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
    func add(
        amount: NSDecimalNumber,
        operation: Operation,
        sourceVault: Vault,
        destinationVault: Vault,
        status: ReimbursementStatus,
        date: Date? = nil,
        notes: String? = nil,
        category: Category
    ) throws -> Reimbursement {
        guard amount.compare(NSDecimalNumber.zero) == .orderedDescending else {
            throw RepositoryError.invalidAmount
        }

        let reimbursement = Reimbursement(context: context)

        reimbursement.id = UUID()
        reimbursement.amount = amount
        reimbursement.originalOperation = operation
        reimbursement.sourceVault = sourceVault
        reimbursement.destinationVault = destinationVault
        reimbursement.status = status.rawValue
        reimbursement.notes = notes
        reimbursement.destinationCategory = category

        try save()
        return reimbursement
    }

    func linkIncomeOperation(_ incomeOperation: Operation, to reimbursement: Reimbursement) throws {
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
    func get(by id: UUID) throws -> Reimbursement? {
        let request: NSFetchRequest<Reimbursement> = Reimbursement.fetchRequest()
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
    func getAll(for operation: Operation) throws -> [Reimbursement] {
        let request: NSFetchRequest<Reimbursement> = Reimbursement.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Reimbursement.originalOperation),
            operation
        )

        /*request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Reimbursement.date), ascending: true)
        ]*/

        return try fetchAll(request)
    }

    /// Fetches all reimbursements deposited in a given vault
    ///
    /// - Parameter vault: The destination vault
    ///
    /// - Returns: A list of reimbursements
    ///
    /// - Throws: An error if fetch fails
    func getAll(depositedIn vault: Vault) throws -> [Reimbursement] {
        let request: NSFetchRequest<Reimbursement> = Reimbursement.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Reimbursement.destinationVault),
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
    func update(
        _ reimbursement: Reimbursement,
        newAmount: NSDecimalNumber? = nil,
        newDestinationVault: Vault? = nil,
        newStatus: ReimbursementStatus? = nil,
        newDate: Date?? = nil,
        newNotes: String? = nil,
        newCategory: Category? = nil
    ) throws {
        if let newAmount {
            guard newAmount.compare(NSDecimalNumber.zero) == .orderedDescending else {
                throw RepositoryError.invalidAmount
            }

            reimbursement.amount = newAmount
        }

        if let newDestinationVault {
            reimbursement.destinationVault = newDestinationVault
        }

        if let newStatus {
            reimbursement.status = newStatus.rawValue
        }
        
        if let newNotes {
            reimbursement.notes = newNotes
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
    func delete(_ reimbursement: Reimbursement) throws {
        context.delete(reimbursement)
        try save()
    }

    /// Deletes all reimbursements associated with an operation
    ///
    /// - Parameter operation: The parent operation
    ///
    /// - Throws: An error if saving context fails
    func deleteAll(for operation: Operation) throws {
        let reimbursements = try getAll(for: operation)
        reimbursements.forEach(context.delete)
        try save()
    }
    
    func deleteAll() throws {
        let request: NSFetchRequest<Reimbursement> = Reimbursement.fetchRequest()
        let reimbursements = try context.fetch(request)
        reimbursements.forEach(context.delete)
        try save()
    }
}

// MARK: - Metrics
extension ReimbursementRepository {
    
    func total(
        in vault: Vault,
        with status: ReimbursementStatus,
        sameVault: Bool,
        between startDate: Date? = nil,
        and endDate: Date? = nil
    ) throws -> Double {
        let request: NSFetchRequest<NSFetchRequestResult> = Reimbursement.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(
                    forKeyPath: #keyPath(Reimbursement.amount)
                )
            ]
        )
        
        expression.expressionResultType = .doubleAttributeType
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(Reimbursement.sourceVault),
                vault
            )
        )
        
        if sameVault {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
                    #keyPath(Reimbursement.destinationVault),
                    vault
                )
            )
        }
        
        if !sameVault {
            predicates.append(
                NSPredicate(
                    format: "%K != %@",
                    #keyPath(Reimbursement.destinationVault),
                    vault
                )
            )
        }
        
        predicates.append(
            NSPredicate(
                format: "%K == %d",
                #keyPath(Reimbursement.status),
                Int(status.rawValue)
            )
        )

        if let startDate {
            predicates.append(
                NSPredicate(
                    format: "%K >= %@",
                    #keyPath(Reimbursement.originalOperation.date),
                    startDate as NSDate
                )
            )
        }

        if let endDate {
            predicates.append(
                NSPredicate(
                    format: "%K <= %@",
                    #keyPath(Reimbursement.originalOperation.date),
                    endDate as NSDate
                )
            )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double ?? 0.0
        
        return total
    }
    
    func total(for operation: Operation) throws -> Double? {
        let request: NSFetchRequest<NSFetchRequestResult> = Reimbursement.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(
                    forKeyPath: #keyPath(Reimbursement.amount)
                )
            ]
        )
        
        expression.expressionResultType = .doubleAttributeType
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(Reimbursement.originalOperation),
                operation
            )
        )
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double
        
        return total
    }
}
