//
//  PersistenceController.swift
//  Vault
//
//  Created by Miguel Solans on 31/03/2026.
//

import CoreData

// MARK: - Repository Errors

enum RepositoryError: LocalizedError {
    case persistentStoreLoadFailed(Error)
    case invalidYear(Int)
    case vaultNotFound(UUID)
    case categoryNotFound(UUID)
    case currencyNotFound(String)
    case invalidAmount
    
    var errorDescription: String? {
        switch self {
        case .persistentStoreLoadFailed(let error):
            return "Failed to load persistent store: \(error.localizedDescription)"
        case .invalidYear(let year):
            return "Invalid year: \(year)"
        case .vaultNotFound(let id):
            return "Vault not found for id \(id.uuidString)"
        case .categoryNotFound(let id):
            return "Category not found for id \(id.uuidString)"
        case .currencyNotFound(let code):
            return "Currency not found for code \(code)"
        case .invalidAmount:
            return "Invalid amount"
        }
    }
}

// MARK: - Context Helpers

extension NSManagedObjectContext {
    /// Saves the context only if there are pending changes.
    ///
    /// This method checks `hasChanges` before attempting to save,
    /// avoiding unnecessary persistence operations.
    ///
    /// - Throws: An error if the save operation fails.
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
}

// MARK: - Persistence Controller

public struct PersistenceConfiguration {
    
    public let modelName: String
    
    public let cloudKitContainerIdentifier: String

    public init(
        modelName: String = "VaultModel",
        cloudKitContainerIdentifier: String
    ) {
        self.modelName = modelName
        self.cloudKitContainerIdentifier = cloudKitContainerIdentifier
    }
}

struct PersistenceController {
    
    /// The Core Data persistent container.
    let container: NSPersistentCloudKitContainer
    
    // Initializes the persistence controller.
    ///
    /// - Parameters:
    ///   - inMemory: A Boolean value indicating whether the store should be created in memory.
    ///               Useful for testing and previews.
    ///   - containerName: The name of the Core Data model.
    ///
    /// - Important: If the persistent store fails to load, the application will crash
    ///   using `fatalError`, as this is considered a non-recoverable setup failure.
    init(
        configuration: PersistenceConfiguration,
        inMemory: Bool = false
    ) {
        guard
            let modelURL = Bundle.module.url(forResource: configuration.modelName, withExtension: "momd")
                ?? Bundle.module.url(forResource: configuration.modelName, withExtension: "mom"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Missing Core Data model named \(configuration.modelName) in VaultCore resources")
        }
        
        container = NSPersistentCloudKitContainer(
            name: configuration.modelName,
            managedObjectModel: model
        )
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Missing persistent store description")
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: configuration.cloudKitContainerIdentifier
        )
        
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )

        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
        
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        var loadError: Error?
        container.loadPersistentStores { description, error in
            if let error {
                loadError = error
                return
            }
            
#if DEBUG
            if let url = description.url {
                print("Core Data store:", url.path)
            }
#endif
        }

        if let loadError {
            fatalError("Failed to load Core Data: \(loadError)")
        }
        
#if DEBUG
        // try! container.initializeCloudKitSchema()
#endif
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.undoManager = nil
        
        backfillOperationTimestamps()
    }
    
    /// Runs on every launch so operations synced from older app versions are also covered.
    private func backfillOperationTimestamps() {
        let context = newBackgroundContext()
        
        context.perform {
            let request: NSFetchRequest<Operation> = Operation.fetchRequest()
            request.predicate = NSPredicate(format: "%K == nil", #keyPath(Operation.createdAt))
            request.fetchBatchSize = 200
            
            do {
                let operations = try context.fetch(request)
                guard !operations.isEmpty else { return }
                
                let now = Date()
                
                for operation in operations {
                    operation.createdAt = operation.date ?? now
                    operation.updatedAt = operation.updatedAt ?? now
                }
                
                try context.save()
            } catch {
                print("PersistenceController | Backfill | Failed: \(error)")
            }
        }
    }
    
    /// The main view context associated with the container.
    ///
    /// - Note: This context is configured to automatically merge changes from parent contexts.
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Creates and returns a new background context.
    ///
    /// - Returns: A configured `NSManagedObjectContext` for background operations.
    ///
    /// - Note: The returned context uses `NSMergeByPropertyObjectTrumpMergePolicy`
    ///   and has its undo manager disabled for performance.
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        context.undoManager = nil
        return context
    }
    
    /// Saves the main view context if there are changes.
    ///
    /// - Throws: An error if the save operation fails.
    func saveViewContext() throws {
        try viewContext.saveIfNeeded()
    }
}

// MARK: - Base Repository Protocol

protocol CoreDataRepository {
    /// The managed object context used by the repository.
    var context: NSManagedObjectContext { get }
}

extension CoreDataRepository {
    
    /// Saves the current context if there are pending changes.
    ///
    /// - Throws: An error if the save operation fails.
    func save() throws {
        try context.saveIfNeeded()
    }
    
    /// Returns the number of objects matching the given fetch request.
    ///
    /// - Parameter request: The fetch request describing the objects to count.
    ///
    /// - Returns: The number of matching objects.
    ///
    /// - Throws: An error if the count operation fails.
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> Int {
        try context.count(for: request)
    }
    
    /// Fetches all objects matching the given request.
    ///
    /// - Parameter request: The fetch request describing the objects to retrieve.
    ///
    /// - Returns: An array of matching objects.
    ///
    /// - Throws: An error if the fetch operation fails.
    func fetchAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        try context.fetch(request)
    }
    
    /// Fetches the first object matching the given request.
    ///
    /// - Parameter request: The fetch request describing the object to retrieve.
    ///
    /// - Returns: The first matching object, or `nil` if no results are found.
    ///
    /// - Throws: An error if the fetch operation fails.
    ///
    /// - Note: This method sets `fetchLimit = 1` for performance optimization.
    func fetchFirst<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> T? {
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
