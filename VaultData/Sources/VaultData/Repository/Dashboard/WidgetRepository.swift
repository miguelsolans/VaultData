//
//  WidgetRepository.swift
//  VaultCore
//
//  Created by Miguel Solans on 04/06/2026.
//

import CoreData
import VaultDomain

public final class WidgetRepository: CoreDataRepository {

    let context: NSManagedObjectContext

    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }
    
    public func get(
        by id: UUID
    ) throws -> DashboardWidgetEntity? {
        
        let request: NSFetchRequest<DashboardWidgetEntity> = DashboardWidgetEntity.fetchRequest()
        request.fetchLimit = 1
        
        let predicate = NSPredicate(
            format: "id == %@",
            id as CVarArg
        )
        
        request.predicate = predicate
        
        return try fetchFirst(request)
    }
    
    public func get(
        from dashboard: DashboardEntity
    ) throws -> [DashboardWidgetEntity]? {
        
        let request: NSFetchRequest<DashboardWidgetEntity> = DashboardWidgetEntity.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(DashboardWidgetEntity.dashboard),
            dashboard
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(DashboardWidgetEntity.sortOrder), ascending: true)
        ]
        
        return try fetchAll(request)
    }
    
    public func create(
        widgetType: DashboardWidgetType,
        isVisible: Bool,
        sortOrder: Int,
        in dashboard: DashboardEntity
    ) throws -> DashboardWidgetEntity {
        let widget = DashboardWidgetEntity(context: context)
        
        widget.id = UUID()
        widget.isVisible = isVisible
        widget.sortOrder = Int16(sortOrder)
        widget.widgetType = widgetType
        widget.dashboard = dashboard
        
        try save()
        
        return widget
    }
    
    public func update(
        _ widget: DashboardWidgetEntity,
        order: Int? = nil,
        isVisible: Bool? = nil
    ) throws {
        if let order {
            widget.sortOrder = Int16(order)
        }

        if let isVisible {
            widget.isVisible = isVisible
        }

        try save()
    }
    
    public func createDefaultWidgets(for dashboard: DashboardEntity) throws {
        
        _ = try create(
            widgetType: .totalIncomeAndSpending,
            isVisible: true,
            sortOrder: 0,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .pieChartSpendingCategories,
            isVisible: true,
            sortOrder: 1,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .totalMainAndOtherIncome,
            isVisible: false,
            sortOrder: 2,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .pieChartIncomeCategories,
            isVisible: false,
            sortOrder: 3,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .barChartSpendingCategories,
            isVisible: false,
            sortOrder: 4,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .barChartIncomeCategories,
            isVisible: false,
            sortOrder: 5,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .keyMetrics,
            isVisible: true,
            sortOrder: 6,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .incomeBreakdown,
            isVisible: false,
            sortOrder: 7,
            in: dashboard
        )
        
        _ = try create(
            widgetType: .spendingBreakdown,
            isVisible: false,
            sortOrder: 8,
            in: dashboard
        )
    }
}
