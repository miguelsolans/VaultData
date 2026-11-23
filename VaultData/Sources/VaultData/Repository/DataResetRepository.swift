import CoreData

public final class DataResetRepository: CoreDataRepository {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    public func deleteAll() throws {
        do {
            try deleteAll(ReimbursementEntity.fetchRequest())
            try deleteAll(OperationEntity.fetchRequest())
            try deleteAll(ScheduledOperationEntity.fetchRequest())
            try deleteAll(DashboardWidgetEntity.fetchRequest())
            try deleteAll(DashboardEntity.fetchRequest())
            try deleteAll(CategoryEntity.fetchRequest())
            try deleteAll(VaultEntity.fetchRequest())
            try deleteAll(SettingsEntity.fetchRequest())
            try save()
        } catch {
            context.rollback()
            throw error
        }
    }
    
    private func deleteAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws {
        for object in try context.fetch(request) {
            context.delete(object)
        }
    }
}
