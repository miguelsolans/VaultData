//
//  OperationRepository+Grouping.swift
//  Vault
//
//  Created by Miguel Solans on 22/04/2026.
//

import Foundation

struct GroupedOperations {
    let date: Date
    let items: [Operation]
}

extension OperationRepository {
    
    func getAllGroupedByDay(
        from vault: Vault,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        calendar: Calendar = .current,
        operationType: OperationType? = nil,
        reimbursementStatus: ReimbursementStatus? = nil
    ) throws -> [GroupedOperations] {
        
        let operations = try getAll(
            from: vault,
            between: startDate,
            and: endDate,
            operationType: operationType,
            reimbursementStatus: reimbursementStatus
        )
        
        let grouped = Dictionary(grouping: operations) { operation in
            calendar.startOfDay(for: operation.date ?? .distantPast)
        }
        
        return grouped
            .map { date, items in
                GroupedOperations(
                    date: date,
                    items: items.sorted {
                        ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
                    }
                )
            }
            .sorted { $0.date > $1.date }
    }
}
