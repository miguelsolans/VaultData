//
//  ScheduledOperationRepository.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import CoreData
import VaultDomain

public final class ScheduledOperationRepository: CoreDataRepository {
    
    public let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

// MARK: - Create

extension ScheduledOperationRepository {
    
    @discardableResult
    public func add(
        title: String,
        amount: Double,
        recurrence: RecurrenceType,
        startDate: Date,
        endDate: Date? = nil,
        nextOcurrenceDate: Date,
        isActive: Bool,
        vault: Vault,
        category: Category
    ) throws -> ScheduledOperation {
        
        let operation = ScheduledOperation(context: context)
        let now = Date()
        
        operation.id = UUID()
        operation.title = title
        operation.amount = amount
        operation.recurrenceType = recurrence
        operation.createdAt = now
        operation.updatedAt = now
        operation.startDate = startDate
        operation.endDate = endDate
        operation.nextOccurrenceDate = nextOcurrenceDate
        operation.occurrenceCount = 0
        operation.isActive = isActive
        operation.vault = vault
        operation.category = category
        
        try save()
        
        return operation
    }
}

// MARK: - Read
extension ScheduledOperationRepository {
    
    /// Fetches a single operation with a given identifer
    ///
    /// - Parameters
    ///     - `id`: The identifier of the operation
    ///
    /// - Returns: The `Operation` instance with the matching `id`, or `nil` if no such operation exists
    ///
    /// - Throws: An error if:
    ///     - Fetch operation fails
    public func get(by id: UUID) throws -> ScheduledOperation? {
        let request: NSFetchRequest<ScheduledOperation> = ScheduledOperation.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try fetchFirst(request)
    }
    
    public func getAll(from vault: Vault) throws -> [ScheduledOperation] {
        
        let request: NSFetchRequest<ScheduledOperation> = ScheduledOperation.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(ScheduledOperation.vault),
            vault
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\ScheduledOperation.createdAt, order: .forward))
        ]
        
        return try fetchAll(request)
    }

    public func getDue(asOf date: Date) throws -> [ScheduledOperation] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return []
        }

        let request: NSFetchRequest<ScheduledOperation> = ScheduledOperation.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == YES AND %K < %@",
            #keyPath(ScheduledOperation.isActive),
            #keyPath(ScheduledOperation.nextOccurrenceDate),
            startOfTomorrow as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\ScheduledOperation.nextOccurrenceDate, order: .forward))
        ]
        return try fetchAll(request)
    }
    
    public func getAll(from vault: Vault, active: Bool) throws -> [ScheduledOperation] {
        
        let request: NSFetchRequest<ScheduledOperation> = ScheduledOperation.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(ScheduledOperation.vault),
                vault
            )
        )
        
        predicates.append(
            NSPredicate(
                format: "%K == %d",
                #keyPath(ScheduledOperation.isActive),
                active
            )
        )
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.sortDescriptors = [
            NSSortDescriptor(SortDescriptor(\ScheduledOperation.createdAt, order: .forward))
        ]
        
        return try fetchAll(request)
    }
}

// MARK: - Update
extension ScheduledOperationRepository {
    
}

// MARK: - Delete
extension ScheduledOperationRepository {
    
    public func delete(_ operation: ScheduledOperation) throws {
        context.delete(operation)
        try save()
    }
}
