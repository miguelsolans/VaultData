//
//  DashboardRepository.swift
//  VaultCore
//
//  Created by Miguel Solans on 03/06/2026.
//

import CoreData

public final class DashboardRepository: CoreDataRepository {

    let context: NSManagedObjectContext

    init(
        context: NSManagedObjectContext
    ) {
        self.context = context
    }
    
    public func create(for vault: VaultEntity) throws -> DashboardEntity {
        let dashboard = DashboardEntity(context: context)
        
        dashboard.id = UUID()
        dashboard.vault = vault
        
        try save()
        
        return dashboard
    }
    
    public func get(by id: UUID) throws -> DashboardEntity? {
        let request: NSFetchRequest<DashboardEntity> = DashboardEntity.fetchRequest()
        request.fetchLimit = 1
        
        request.predicate = NSPredicate(
            format: "id == %@",
            id as CVarArg
        )
        
        return try fetchFirst(request)
    }
    
    public func get(for vault: VaultEntity) throws -> DashboardEntity? {
        let request: NSFetchRequest<DashboardEntity> = DashboardEntity.fetchRequest()
        request.fetchLimit = 1
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(DashboardEntity.vault),
            vault
        )
        
        return try fetchFirst(request)
    }
}
