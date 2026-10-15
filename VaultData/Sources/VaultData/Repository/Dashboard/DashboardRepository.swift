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
    
    func create(for vault: Vault) throws -> Dashboard {
        let dashboard = Dashboard(context: context)
        
        dashboard.id = UUID()
        dashboard.vault = vault
        
        try save()
        
        return dashboard
    }
    
    func get(by id: UUID) throws -> Dashboard? {
        let request: NSFetchRequest<Dashboard> = Dashboard.fetchRequest()
        request.fetchLimit = 1
        
        request.predicate = NSPredicate(
            format: "id == %@",
            id as CVarArg
        )
        
        return try fetchFirst(request)
    }
    
    func get(for vault: Vault) throws -> Dashboard? {
        let request: NSFetchRequest<Dashboard> = Dashboard.fetchRequest()
        request.fetchLimit = 1
        
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(Dashboard.vault),
            vault
        )
        
        return try fetchFirst(request)
    }
}
