//
//  OperationRepository+Metrics.swift
//  Vault
//
//  Created by Miguel Solans on 13/04/2026.
//

import CoreData

public enum CategoryFilter {
    case any
    case matching(Category)
    case excluding(Category)
}

internal enum ExpressionFunction: String {
    case sum = "sum:"
    case average = "average:"
    case result = "result"
}

extension OperationRepository {
    
    public func totalAmount(
        in vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        of type: OperationType,
        category categoryFilter: CategoryFilter = .any
    ) throws -> Double {
        
        let request: NSFetchRequest<NSFetchRequestResult> = Operation.fetchRequest()
        
        let expression = NSExpressionDescription()
        expression.name = ExpressionFunction.result.rawValue
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(forKeyPath: #keyPath(Operation.amount))
            ]
        )
        expression.expressionResultType = .doubleAttributeType
        
        var predicates: [NSPredicate] = []
        
        // Always required
        predicates.append(
            NSPredicate(
                format: "%K == %@",
                #keyPath(Operation.vault),
                vault
            )
        )
        
        predicates.append(
            NSPredicate(
                format: "%K == %d",
                #keyPath(Operation.type),
                Int(type.rawValue)
            )
        )
        
        // Optional filters
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
        
        switch categoryFilter {
        case .any:
            break

        case .matching(let category):
            predicates.append(
                NSPredicate(format: "%K == %@", #keyPath(Operation.category), category)
            )

        case .excluding(let category):
            predicates.append(
                NSPredicate(format: "%K != %@", #keyPath(Operation.category), category)
            )
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double ?? 0.0
        
        return total
    }
    
    public func averageAmount(
        in vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        of type: OperationType
    ) throws -> Double {
        
        let request: NSFetchRequest<NSFetchRequestResult> = Operation.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.average.rawValue,
            arguments: [
                NSExpression(forKeyPath: #keyPath(Operation.amount))
            ]
        )
        
        expression.expressionResultType = .doubleAttributeType
        
        var predicates: [NSPredicate] = []
        
        let vaultPredicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Operation.vault),
            vault
        )
        
        predicates.append(vaultPredicate)
        
        let typePredicate = NSPredicate(
            format: "%K == %d",
            #keyPath(Operation.type),
            Int(type.rawValue)
        )
        
        predicates.append(typePredicate)
        
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
        
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double ?? 0.0
        
        return total
    }
    
    public func totalAmountHidden(in vault: Vault, between startDate: Date, and endDate: Date, of type: OperationType) throws -> Double {
        let request: NSFetchRequest<NSFetchRequestResult> = Operation.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(forKeyPath: #keyPath(Operation.amount))
            ]
        )
        
        expression.expressionResultType = .doubleAttributeType
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(
                format: "%K == %@",
                #keyPath(Operation.vault),
                vault
            ),
            NSPredicate(
                format: "%K >= %@",
                #keyPath(Operation.date),
                startDate as NSDate
            ),
            NSPredicate(
                format: "%K <= %@",
                #keyPath(Operation.date),
                endDate as NSDate
            ),
            NSPredicate(
                format: "%K == %d",
                #keyPath(Operation.type),
                Int(type.rawValue)
            ),
            NSPredicate(
                format: "category.visibleInPlot == NO"
            )
        ])
        
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double ?? 0.0
        
        return total
    }
    
    public func totalReimbursed(in vault: Vault, withStatus status: ReimbursementStatus, sameDestinationVault: Bool) throws -> Double {
        let request: NSFetchRequest<NSFetchRequestResult> = Reimbursement.fetchRequest()
        
        let expression = NSExpressionDescription()
        
        expression.name = ExpressionFunction.result.rawValue
        
        expression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(forKeyPath: #keyPath(Reimbursement.amount))
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
        
        if sameDestinationVault {
            predicates.append(
                NSPredicate(
                    format: "%K == %@",
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
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates);
        
        request.propertiesToFetch = [expression]
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request) as? [[String: Any]]
        
        let total = result?.first?[ExpressionFunction.result.rawValue] as? Double ?? 0.0
        
        return total
    }
    
    public func totalAmountPerCategory(
        in vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        of type: OperationType,
        onlyVisible visible: Bool? = nil,
        ascending order: Bool? = nil
    ) throws -> [AmountPerCategory] {
        let request = NSFetchRequest<NSDictionary>(entityName: "Operation")
        
        let sumExpression = NSExpressionDescription()
        
        sumExpression.name = ExpressionFunction.result.rawValue
        
        sumExpression.expression = NSExpression(
            forFunction: ExpressionFunction.sum.rawValue,
            arguments: [
                NSExpression(forKeyPath: #keyPath(Operation.amount))
            ]
        )
        
        sumExpression.expressionResultType = .doubleAttributeType
        
        request.propertiesToFetch = [
            "category.id",
            "category.name",
            "category.color",
            sumExpression
        ]
        
        request.propertiesToGroupBy = [
            "category.id",
            "category.name",
            "category.color"
        ]
        
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
        
        let operationTypePredicate = NSPredicate(
            format: "%K == %d",
            #keyPath(Operation.type),
            Int(type.rawValue)
        )
        
        predicates.append(operationTypePredicate)
        
        if let visible {
            let predicate = NSPredicate(
                format: "category.visibleInPlot == %d",
                visible
            )
            
            predicates.append(predicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        if let order {
            request.sortDescriptors = [
                NSSortDescriptor(
                    key: ExpressionFunction.result.rawValue,
                    ascending: false
                )
            ]
        }
        
        request.resultType = .dictionaryResultType
        
        let result = try context.fetch(request)
        
        return result.compactMap { dict in
            
            let id = dict["category.id"] as! UUID
            let amount = dict[ExpressionFunction.result.rawValue] as! Double
            let title = dict["category.name"] as! String
            let color = dict["category.color"] as! String
            
            
            return AmountPerCategory(
                id: id,
                title: title,
                amount: amount,
                hexColor: color
            )
        }
    }

    public func netExpenseAmountPerCategory(
        in vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        onlyVisible visible: Bool? = nil
    ) throws -> [AmountPerCategory] {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(
                format: "%K == %@",
                #keyPath(Operation.vault),
                vault
            ),
            NSPredicate(
                format: "%K == %d",
                #keyPath(Operation.type),
                Int(OperationType.expense.rawValue)
            )
        ]

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

        if let visible {
            predicates.append(
                NSPredicate(
                    format: "category.visibleInPlot == %d",
                    visible
                )
            )
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.relationshipKeyPathsForPrefetching = [
            #keyPath(Operation.category),
            #keyPath(Operation.reimbursements)
        ]

        let operations = try fetchAll(request)

        struct CategoryTotal {
            let title: String
            let hexColor: String
            var amount: Double
        }

        let totalsByCategory = operations.reduce(into: [UUID: CategoryTotal]()) { result, operation in
            guard
                let category = operation.category,
                let categoryID = category.id,
                let title = category.name,
                let hexColor = category.color
            else {
                return
            }

            let reimbursements = (operation.reimbursements as? Set<Reimbursement>) ?? []
            let receivedSameVaultReimbursements = reimbursements
                .filter { reimbursement in
                    reimbursement.reimbursementStatus == .received &&
                    reimbursement.sourceVault?.id == vault.id &&
                    reimbursement.destinationVault?.id == vault.id
                }
                .reduce(0) { total, reimbursement in
                    total + (reimbursement.amount?.doubleValue ?? 0)
                }

            let netAmount = operation.amount - receivedSameVaultReimbursements

            if result[categoryID] == nil {
                result[categoryID] = CategoryTotal(
                    title: title,
                    hexColor: hexColor,
                    amount: 0
                )
            }

            result[categoryID]?.amount += netAmount
        }

        return totalsByCategory.map { categoryID, total in
            AmountPerCategory(
                id: categoryID,
                title: total.title,
                amount: total.amount,
                hexColor: total.hexColor
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    /// Fetches the `Operation` of a given type with the biggest amount in a specific `Vault`.
    ///
    /// - Parameters:
    ///   - vault: The vault where to look for the operation.
    ///   - type: The operation type to filter by.
    ///   - year: An optional year to restrict the search.
    ///
    /// - Returns: The matching `Operation` with the highest amount, or `nil` if none exists.
    ///
    /// - Throws:
    ///   - `RepositoryError.invalidYear(_:)` if the provided year is invalid.
    ///   - Any fetch-related error.
    public func getBiggestOperation(
        of type: OperationType,
        from vault: Vault,
        year: Int? = nil
    ) throws -> Operation? {
        let request: NSFetchRequest<Operation> = Operation.fetchRequest()
        request.fetchLimit = 1

        var predicates: [NSPredicate] = [
            NSPredicate(format: "%K == %@", #keyPath(Operation.vault), vault),
            NSPredicate(format: "%K == %d", #keyPath(Operation.type), Int(type.rawValue))
        ]

        if let year {
            guard (1...9999).contains(year) else {
                throw RepositoryError.invalidYear(year)
            }

            let calendar = Calendar.current

            guard
                let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
            else {
                throw RepositoryError.invalidYear(year)
            }

            predicates.append(
                NSPredicate(
                    format: "%K >= %@ AND %K < %@",
                    #keyPath(Operation.date),
                    startOfYear as NSDate,
                    #keyPath(Operation.date),
                    endOfYear as NSDate
                )
            )
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Operation.amount), ascending: false),
            NSSortDescriptor(key: #keyPath(Operation.date), ascending: false)
        ]

        return try fetchFirst(request)
    }
}
