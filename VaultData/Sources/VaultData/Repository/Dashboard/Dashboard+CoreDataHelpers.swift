//
//  File.swift
//  VaultCore
//
//  Created by Miguel Solans on 01/10/2026.
//

import Foundation

public enum DashboardWidgetType: Int16 {
    case totalIncomeAndSpending = 0
    case totalMainAndOtherIncome = 1
    case pieChartSpendingCategories = 2
    case pieChartIncomeCategories = 3
    case barChartSpendingCategories = 4
    case barChartIncomeCategories = 5
    case keyMetrics = 6
    case incomeBreakdown = 7
    case spendingBreakdown = 8
    
    case unknown
}

extension DashboardWidget {
    public var widgetType: DashboardWidgetType {
        get {
            return DashboardWidgetType(rawValue: type) ?? .unknown
        }
        set {
            type = newValue.rawValue
        }
    }
}
