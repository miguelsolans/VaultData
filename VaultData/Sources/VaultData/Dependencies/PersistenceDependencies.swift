//
//  PersistenceDependencies.swift
//  VaultData
//
//  Created by Miguel Solans on 15/10/2026.
//

import Foundation

public final class PersistenceDependencies {
    
    private let persistence: PersistenceController
    
    private lazy var persistenceNotifications: PersistenceChangeNotifier = {
        PersistenceChangeNotifier(persistenceContainer: persistence)
    }()
    
    // MARK: - Repositories
    
    public let vaultRepository: VaultRepository
    
    public let operationRepository: OperationRepository
    
    public let categoryRepository: CategoryRepository
    
    public let currencyRepository: CurrencyRepository
    
    public let reimbursementRepository: ReimbursementRepository
    
    public let dashboardRepository: DashboardRepository
    
    public let widgetRepository: WidgetRepository
    
    public let scheduledOperationRepository: ScheduledOperationRepository
    
    public let settingsRepository: SettingsRepository
    
    public init(configuration: PersistenceConfiguration) {
        self.persistence = PersistenceController(configuration: configuration)
        
        let context = persistence.viewContext
        
        self.vaultRepository = VaultRepository(context: context)
        
        self.operationRepository = OperationRepository(context: context)
        
        self.categoryRepository = CategoryRepository(context: context)
        
        self.currencyRepository = CurrencyRepository(context: context)
        
        self.reimbursementRepository = ReimbursementRepository(context: context)
        
        self.dashboardRepository = DashboardRepository(context: context)
        
        self.widgetRepository = WidgetRepository(context: context)
        
        self.scheduledOperationRepository = ScheduledOperationRepository(context: context)
        
        self.settingsRepository = SettingsRepository(context: context)
    }
}
