//
//  PersistenceController.swift
//  Vault
//
//  Created by Miguel Solans on 31/03/2026.
//

import CoreData

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

    let cloudKitContainerIdentifier: String
    
    // Initializes the persistence controller.
    ///
    /// - Parameters:
    ///   - inMemory: A Boolean value indicating whether the store should be created in memory.
    ///               Useful for testing and previews.
    ///   - containerName: The name of the Core Data model.
    ///
    /// - Throws: An error if the model or persistent store description cannot be loaded.
    init(
        configuration: PersistenceConfiguration,
        inMemory: Bool = false
    ) throws {
        guard
            let modelURL = Bundle.module.url(forResource: configuration.modelName, withExtension: "momd")
                ?? Bundle.module.url(forResource: configuration.modelName, withExtension: "mom"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            throw PersistenceControllerError.modelNotFound(configuration.modelName)
        }
        
        let container = NSPersistentCloudKitContainer(
            name: configuration.modelName,
            managedObjectModel: model
        )
        
        guard let description = container.persistentStoreDescriptions.first else {
            throw PersistenceControllerError.missingStoreDescription
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
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        self.container = container
        self.cloudKitContainerIdentifier = configuration.cloudKitContainerIdentifier
    }

    func loadPersistentStores() async throws {
        let storeCount = container.persistentStoreDescriptions.count

        guard storeCount > 0 else {
            throw PersistenceControllerError.missingStoreDescription
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let tracker = PersistentStoreLoadTracker(
                expectedStoreCount: storeCount,
                continuation: continuation
            )

            container.loadPersistentStores { description, error in
#if DEBUG
                if error == nil, let url = description.url {
                    print("Core Data store:", url.path)
                }
#endif

                Task {
                    await tracker.record(error: error)
                }
            }
        }
        
#if DEBUG
        // try! container.initializeCloudKitSchema()
#endif
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.undoManager = nil
        
        migrateLegacyData()
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

private actor PersistentStoreLoadTracker {
    private let expectedStoreCount: Int
    private var loadedStoreCount = 0
    private var firstError: Error?
    private var continuation: CheckedContinuation<Void, Error>?

    init(
        expectedStoreCount: Int,
        continuation: CheckedContinuation<Void, Error>
    ) {
        self.expectedStoreCount = expectedStoreCount
        self.continuation = continuation
    }

    func record(error: Error?) {
        if firstError == nil {
            firstError = error
        }

        loadedStoreCount += 1

        guard loadedStoreCount == expectedStoreCount,
              let continuation else {
            return
        }

        self.continuation = nil

        if let firstError {
            continuation.resume(throwing: firstError)
        } else {
            continuation.resume()
        }
    }
}

enum PersistenceControllerError: LocalizedError {
    case modelNotFound(String)
    case missingStoreDescription

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelName):
            return "Missing Core Data model named \(modelName)."
        case .missingStoreDescription:
            return "Missing persistent store description."
        }
    }
}

extension PersistenceController {
    
    private func migrateLegacyData() {
        // Apply migrations if needed
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
    public func save() throws {
        try context.saveIfNeeded()
    }
    
    /// Returns the number of objects matching the given fetch request.
    ///
    /// - Parameter request: The fetch request describing the objects to count.
    ///
    /// - Returns: The number of matching objects.
    ///
    /// - Throws: An error if the count operation fails.
    public func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> Int {
        try context.count(for: request)
    }
    
    /// Fetches all objects matching the given request.
    ///
    /// - Parameter request: The fetch request describing the objects to retrieve.
    ///
    /// - Returns: An array of matching objects.
    ///
    /// - Throws: An error if the fetch operation fails.
    public func fetchAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
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
    public func fetchFirst<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> T? {
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
