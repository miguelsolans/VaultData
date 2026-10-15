//
//  SettingsRepository.swift
//  VaultCore
//
//  Created by Miguel Solans on 14/07/2026.
//

import CoreData

public enum SettingsRepositoryError: LocalizedError {
    case settingsNotFound
}

public final class SettingsRepository: CoreDataRepository {
    
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension SettingsRepository {
    public func create() throws -> Settings {
        
        let settings = Settings(context: context)
        
        try save()
        
        return settings
    }
    
    public func get() throws -> Settings? {
        
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        request.fetchLimit = 1
        
        return try fetchFirst(request)
    }
}

extension SettingsRepository {
    
    public func setFavorite(vault: Vault) throws -> Settings {
        
        guard let settings = try get() else {
            throw SettingsRepositoryError.settingsNotFound
        }
        
        settings.favoriteVault = vault
        
        try save()
        
        return settings
    }
    
    public func getFavorite() throws -> Vault? {
        
        guard let settings = try get() else {
            throw SettingsRepositoryError.settingsNotFound
        }
        
        return settings.favoriteVault
    }
}

extension SettingsRepository {
    
    public func setLastOpenedDate(date: Date) throws {
        
        guard let settings = try get() else {
            throw SettingsRepositoryError.settingsNotFound
        }
        
        settings.lastOpened = date
        
        try save()
    }
}
