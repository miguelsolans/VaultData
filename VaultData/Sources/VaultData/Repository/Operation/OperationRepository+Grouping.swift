//
//  OperationRepository+Grouping.swift
//  Vault
//
//  Created by Miguel Solans on 22/04/2026.
//

import Foundation
import VaultDomain

public struct GroupedOperationsEntity {
    public let date: Date
    
    public let items: [OperationEntity]
}

extension OperationRepository {
    
    public func getAllGroupedByDay(
        from vault: VaultEntity,
        between startDate: Date? = nil,
        and endDate: Date? = nil,
        calendar: Calendar = .current,
        operationType: OperationType? = nil,
        reimbursementStatus: ReimbursementStatus? = nil
    ) throws -> [GroupedOperationsEntity] {
        
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
                GroupedOperationsEntity(
                    date: date,
                    items: items.sorted {
                        ($0.date ?? .distantPast) > ($1.date ?? .distantPast)
                    }
                )
            }
            .sorted { $0.date > $1.date }
    }
}
